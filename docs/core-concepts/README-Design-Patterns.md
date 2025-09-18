# Guía de Patrones de Diseño en el Proyecto

Los patrones de diseño son soluciones reutilizables a problemas comunes que ocurren en el diseño de software. No son librerías ni código que se pueda importar, sino "recetas" o buenas prácticas que nos ayudan a escribir un código más flexible, eficiente y mantenible.

Aquí veremos tres patrones clásicos y cómo se aplican (o se relacionan) en un entorno de Spring Boot.

1.  **Singleton**
2.  **Factory**
3.  **Observer**

---

### 1. Patrón Singleton

**¿Qué es?** El patrón Singleton garantiza que una clase tenga una única instancia en toda la aplicación y proporciona un punto de acceso global a ella.

**¿Por qué es útil?**
*   **Recursos compartidos**: Ideal para gestionar el acceso a recursos que por naturaleza son únicos, como una conexión a base de datos, un gestor de configuración o un pool de threads.
*   **Estado global**: Permite mantener un estado global accesible desde cualquier parte de la aplicación de forma controlada.

**Relación con Spring Boot:**

En Spring, no necesitamos implementar el patrón Singleton manualmente. **Por defecto, todos los beans gestionados por el contenedor de Spring son Singletons**.

Cuando anotamos una clase con `@Service`, `@Repository`, `@Component` o `@RestController`, Spring se encarga de:
1.  Crear **una única instancia** de esa clase durante el arranque de la aplicación.
2.  Guardarla en su "contenedor de inversión de control" (IoC container).
3.  Inyectar esa misma instancia en cualquier otra clase que la necesite (usando `@Autowired`).

**Ejemplo en nuestro proyecto:**

Nuestro `UserServiceImpl` será un Singleton gestionado por Spring.

```java
@Service // Por defecto, esto es un Singleton
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;

    // Spring inyecta la única instancia de UserRepository
    @Autowired
    public UserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // ... métodos del servicio
}
```

Cada vez que otra clase, como `UserController`, requiera un `UserService`, Spring le proporcionará la misma instancia. Esto es eficiente y seguro en un entorno multihilo, ya que Spring gestiona el ciclo de vida del bean.

---

### 2. Patrón Factory (Fábrica)

**¿Qué es?** El patrón Factory proporciona una interfaz para crear objetos en una superclase, pero permite que las subclases alteren el tipo de objetos que se crearán. Es decir, delega la responsabilidad de la instanciación a sus subclases.

**¿Por qué es útil?**
*   **Desacoplamiento**: El código cliente no necesita saber cómo se crea un objeto. Solo pide a la fábrica "dame un objeto de este tipo" y la fábrica se encarga de la lógica de creación.
*   **Flexibilidad**: Facilita la adición de nuevos tipos de productos sin modificar el código cliente.

**Ejemplo en nuestro proyecto:**

Imaginemos que nuestro sistema necesita enviar diferentes tipos de notificaciones (`EMAIL`, `SMS`, `PUSH`). Una fábrica puede centralizar la creación de la estrategia de notificación adecuada.

Primero, definimos una interfaz común:

```java
public interface NotificationSender {
    void send(String to, String message);
}
```

Luego, las implementaciones concretas:

```java
public class EmailSender implements NotificationSender { /* ... */ }
public class SmsSender implements NotificationSender { /* ... */ }
```

Y finalmente, la fábrica:

```java
// NotificationFactory.java
@Component
public class NotificationFactory {
    public NotificationSender getSender(String type) {
        if ("EMAIL".equalsIgnoreCase(type)) {
            return new EmailSender();
        }
        if ("SMS".equalsIgnoreCase(type)) {
            return new SmsSender();
        }
        throw new IllegalArgumentException("Tipo de notificación no soportado: " + type);
    }
}
```

Un servicio usaría la fábrica para obtener el enviador correcto sin conocer los detalles de su creación:

```java
@Service
public class NotificationService {
    private final NotificationFactory factory;

    @Autowired
    public NotificationService(NotificationFactory factory) {
        this.factory = factory;
    }

    public void sendNotification(String type, String to, String message) {
        NotificationSender sender = factory.getSender(type);
        sender.send(to, message);
    }
}
```

---

### 3. Patrón Observer (Observador)

**¿Qué es?** El patrón Observer define una dependencia de uno a muchos entre objetos, de modo que cuando un objeto (el "sujeto" o "publicador") cambia su estado, todos sus dependientes (los "observadores") son notificados y actualizados automáticamente.

**¿Por qué es útil?**
*   **Desacoplamiento**: El publicador no necesita saber quiénes son sus observadores, solo que existen. Esto permite añadir o quitar observadores dinámicamente.
*   **Reactividad**: Facilita la creación de sistemas reactivos donde un evento desencadena múltiples acciones en diferentes partes del sistema.

**Relación con Spring Boot (Eventos de Aplicación):**

Spring tiene un mecanismo de eventos incorporado que es una implementación perfecta del patrón Observer.

1.  **El Sujeto (Publicador)**: Es una clase que publica un evento.
2.  **El Evento**: Es una clase que representa lo que ha sucedido (ej: `UserRegisteredEvent`). Debe extender `ApplicationEvent`.
3.  **Los Observadores (Listeners)**: Son métodos anotados con `@EventListener` que reaccionan cuando se publica un evento específico.

**Ejemplo en nuestro proyecto:**

Cuando un nuevo usuario se registra, queremos que sucedan dos cosas:
1.  Enviar un email de bienvenida.
2.  Asignarle un bonus de registro.

**1. Definir el evento:**

```java
// El evento contiene la información relevante
public class UserRegisteredEvent extends ApplicationEvent {
    private final User user;

    public UserRegisteredEvent(Object source, User user) {
        super(source);
        this.user = user;
    }

    public User getUser() {
        return user;
    }
}
```

**2. Publicar el evento:**

El `UserService` publicará el evento después de guardar el usuario.

```java
@Service
public class UserServiceImpl implements UserService {
    private final ApplicationEventPublisher eventPublisher;
    // ... otros componentes

    @Autowired
    public UserServiceImpl(ApplicationEventPublisher eventPublisher, ...) {
        this.eventPublisher = eventPublisher;
    }

    public User register(User user) {
        // ... lógica para guardar el usuario
        User savedUser = userRepository.save(user);

        // Publicamos el evento. Spring se encargará de notificar a los listeners.
        eventPublisher.publishEvent(new UserRegisteredEvent(this, savedUser));

        return savedUser;
    }
}
```

**3. Crear los observadores (listeners):**

Podemos tener múltiples listeners en diferentes partes de la aplicación, totalmente desacoplados entre sí.

```java
@Component
public class WelcomeEmailSender {
    @EventListener
    public void handleUserRegisteredEvent(UserRegisteredEvent event) {
        User user = event.getUser();
        System.out.println("Enviando email de bienvenida a: " + user.getEmail());
        // ... lógica para enviar email
    }
}

@Component
public class RegistrationBonusService {
    @EventListener
    public void handleUserRegisteredEvent(UserRegisteredEvent event) {
        User user = event.getUser();
        System.out.println("Asignando bonus de registro al usuario: " + user.getUsername());
        // ... lógica para dar el bonus
    }
}
```

Así, el `UserService` no sabe nada sobre emails o bonus. Su única responsabilidad es registrar al usuario y anunciar que lo ha hecho. El resto del sistema reacciona a ese anuncio. Esto es extremadamente potente para construir sistemas desacoplados y extensibles.
