# Proyecto Avanzado de Microservicios en Java para Preparación de Entrevistas

¡Bienvenido/a! Este repositorio es un proyecto **Full-Stack de microservicios** diseñado para servir como una guía de estudio completa y práctica para una entrevista de trabajo como Desarrollador/a Java senior.

El objetivo no es solo tener el código, sino entender el **qué**, el **cómo** y el **porqué** de cada tecnología, buena práctica y decisión de arquitectura en un entorno de microservicios del mundo real.

Este proyecto ha sido construido para demostrar un amplio abanico de competencias, desde la programación concurrente y reactiva hasta la contenerización y el despliegue en la nube con Infraestructura como Código.

## 🏛️ Arquitectura del Sistema

El sistema se compone de dos microservicios independientes que se comunican de forma asíncrona a través de un bróker de eventos (Kafka).

1.  **`user-service` (Servicio de Usuarios)**
    *   **Responsabilidad**: Gestionar toda la lógica de negocio relacionada con los usuarios (creación, consulta, etc.).
    *   **Stack Tecnológico**:
        *   **Framework**: Spring Boot con Spring MVC (tradicional, basado en hilos).
        *   **Base de Datos**: PostgreSQL (Relacional).
        *   **Acceso a Datos**: Spring Data JPA.
        *   **Buenas Prácticas**: Gestión de transacciones explícita (`@Transactional`), implementación de caché con Redis.
        *   **Rol en EDA**: **Productor** de eventos. Publica un evento `UserCreatedEvent` cuando un usuario es creado.

2.  **`order-service` (Servicio de Órdenes)**
    *   **Responsabilidad**: Gestionar toda la lógica de negocio relacionada con las órdenes.
    *   **Stack Tecnológico**:
        *   **Framework**: Spring Boot con Spring WebFlux (reactivo, no bloqueante).
        *   **Base de Datos**: MongoDB (NoSQL).
        *   **Acceso a Datos**: Spring Data Reactive MongoDB.
        *   **Buenas Prácticas**: Programación reactiva de extremo a extremo, implementación de caché con Redis.
        *   **Rol en EDA**: **Consumidor** de eventos. Se suscribe a los eventos de creación de usuarios.

### Diagrama de Arquitectura Local
![Diagrama de Arquitectura](https://i.imgur.com/YOUR_DIAGRAM_URL.png)  <!-- Placeholder for a future diagram -->

---

## 🗺️ Mapa de Aprendizaje Cubierto

Este proyecto sirve como una implementación práctica de los siguientes temas clave de ingeniería de software. La documentación detallada de cada tema se encuentra en la carpeta `/docs`.

1.  **Programación Orientada a Objetos y Patrones de Diseño** (`docs/core-concepts`)
2.  **Bases de Datos Relacionales y NoSQL** (`user-service`, `order-service`, `docs/database`)
3.  **Gestión de Transacciones (ACID)** (`user-service`, `docs/database/relational`)
4.  **Programación Concurrente vs. Reactiva** (Contraste entre `user-service` y `order-service`, `docs/concurrency-reactive`)
5.  **Arquitectura Orientada a Eventos con Kafka** (Comunicación entre servicios, `docs/architecture`)
6.  **Estrategias de Caché con Redis** (Implementado en ambos servicios, `docs/database/nosql`)
7.  **Contenerización con Docker** (`Dockerfile` en cada servicio)
8.  **Orquestación Local con Docker Compose** (`docker-compose.yml`)
9.  **Infraestructura como Código (IaC) con Terraform** (`infrastructure`)
10. **Despliegue en la Nube con AWS ECS Fargate** (`infrastructure`)
11. **Metodologías de Pruebas (Unitarias y de Integración)** (Tests en ambos servicios, `docs/testing`)

---

## 🚀 Cómo Empezar (Entorno Local)

Sigue estos pasos para levantar todo el ecosistema de microservicios en tu máquina local.

**Pre-requisitos**:
*   Tener instalado Java 21, Maven y Docker.

**Pasos**:

1.  **Clona el repositorio**:
    ```bash
    git clone <URL_DEL_REPOSITORIO>
    cd <NOMBRE_DEL_REPOSITORIO>
    ```

2.  **Levanta todo el entorno con Docker Compose**:
    Este comando construirá las imágenes Docker para `user-service` y `order-service` y levantará todos los contenedores definidos en `docker-compose.yml` (ambos servicios, PostgreSQL, MongoDB, Kafka, Zookeeper y Redis).
    ```bash
    docker-compose up --build
    ```
    La primera vez puede tardar varios minutos mientras se descargan las imágenes base y se compilan los proyectos.

3.  **Interactúa con los servicios**:
    *   **User Service**: Disponible en `http://localhost:8081`
        *   `POST /api/v1/users` - Crea un nuevo usuario.
        *   `GET /api/v1/users/{id}` - Obtiene un usuario por ID.
    *   **Order Service**: Disponible en `http://localhost:8082`
        *   `POST /api/v1/orders` - Crea una nueva orden.
        *   `GET /api/v1/orders/{id}` - Obtiene una orden por ID.

4.  **Verifica la comunicación con Kafka**:
    *   Crea un usuario nuevo con una petición `POST` al `user-service`.
    *   Observa los logs del `order-service` en la consola de Docker. Deberías ver un mensaje que indica que ha consumido el `UserCreatedEvent`.

## ☁️ Cómo Desplegar en la Nube (AWS)

Las instrucciones detalladas para desplegar toda esta arquitectura en AWS usando Terraform se encuentran en el `README` de la carpeta de infraestructura:
[**Guía de Despliegue en la Nube**](./infrastructure/README-Terraform.md)
