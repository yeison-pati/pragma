# Guía de Arquitectura Orientada a Eventos (EDA) con Kafka

La **Arquitectura Orientada a Eventos (EDA)** es un paradigma de diseño de software en el que la comunicación entre los componentes (en nuestro caso, microservicios) se realiza mediante la producción y consumo de **eventos**.

Un evento es una notificación de que "algo ha sucedido". En lugar de que un servicio llame directamente a otro (comunicación síncrona y acoplada), un servicio emite un evento a un "canal" y otros servicios interesados se suscriben a ese canal para reaccionar al evento.

En nuestro proyecto, el "canal" es un **bróker de mensajería**, y hemos elegido **Apache Kafka**, el estándar de la industria para el streaming de eventos a gran escala.

### Beneficios Clave de EDA

*   **Desacoplamiento (Decoupling)**: El productor de eventos no necesita saber quiénes son los consumidores, ni siquiera si están en línea. El `user-service` puede publicar un evento `UserCreated` sin saber que el `order-service` (o cualquier otro servicio futuro) está escuchando.
*   **Escalabilidad**: Podemos añadir más consumidores a un tópico de Kafka para procesar eventos en paralelo, lo que permite escalar partes del sistema de forma independiente.
*   **Resiliencia y Tolerancia a Fallos**: Si el `order-service` está caído cuando se crea un usuario, el evento permanece en Kafka. Una vez que el `order-service` se recupera, puede procesar el evento que se perdió. Esto evita la pérdida de datos.
*   **Asincronismo**: El `user-service` no tiene que esperar una respuesta del `order-service`. Publica el evento y continúa con su trabajo, lo que resulta en una menor latencia y una mejor experiencia de usuario.

---

### Flujo de Eventos en Nuestro Proyecto: Creación de un Usuario

Hemos implementado un flujo de eventos robusto y transaccional para la creación de usuarios.

**Diagrama del Flujo:**

```
[Cliente] --1. POST /api/v1/users--> [user-service]
                                          |
                                          |--2. Inicia Transacción en BD
                                          |     |
                                          |     |--> 3. Guarda el usuario en PostgreSQL
                                          |     |
                                          |     |--4. Publica un evento LOCAL (Spring Event)
                                          |
                                          |--5. Hace COMMIT de la Transacción
                                          |
                                          |--6. @TransactionalEventListener se activa
                                                |
                                                |--> 7. Publica el evento en el Tópico de KAFKA
                                                      |
                                                      |--> [order-service] --8. @KafkaListener consume el evento
                                                            |
                                                            |--> 9. Procesa el evento (ej: lo loguea)
```

#### Paso a Paso (La Implementación)

1.  **`UserServiceImpl`**: Cuando se llama a `createUser()`, la operación se envuelve en una transacción de base de datos (`@Transactional`).
2.  **`ApplicationEventPublisher`**: Después de guardar el usuario en la base de datos, en lugar de llamar directamente a Kafka, el servicio publica un evento **local** de Spring: `eventPublisher.publishEvent(new UserCreatedEvent(...))`.
3.  **El Problema a Evitar**: Si llamáramos a Kafka directamente dentro del método `@Transactional`, podríamos enviar un evento sobre un usuario que, debido a un fallo posterior, nunca llega a ser confirmado (commit) en la base de datos. El consumidor recibiría un evento sobre datos "fantasma".
4.  **La Solución (`@TransactionalEventListener`)**:
    *   Hemos creado un componente `UserEventListeners` con un método que escucha el `UserCreatedEvent` local.
    *   Este método está anotado con `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)`.
    *   Esta anotación le dice a Spring: "No ejecutes este método hasta que la transacción de la que proviene este evento se haya completado con **éxito** (COMMIT)".
5.  **`KafkaProducerService`**: Solo cuando el listener se activa, llama al `KafkaProducerService`, que utiliza el `KafkaTemplate` de Spring para enviar el evento al tópico `user-events-topic`.
6.  **`KafkaConsumerService` (`order-service`)**:
    *   En el `order-service`, un método anotado con `@KafkaListener` está suscrito al tópico `user-events-topic`.
    *   Cuando llega un mensaje, Spring Kafka deserializa automáticamente el payload JSON al objeto `UserCreatedEvent`.
    *   El método del listener se ejecuta, procesando los datos del nuevo usuario.

Este patrón de "publicar localmente y escuchar transaccionalmente" es una **mejor práctica** para construir sistemas de microservicios robustos y consistentes. Demuestra un entendimiento profundo de los desafíos que van más allá de una simple llamada a `kafkaTemplate.send()`.
