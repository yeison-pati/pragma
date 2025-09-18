# Guía de Programación Orientada a Objetos (POO) en el Proyecto

La Programación Orientada a Objetos (POO) no es solo una forma de programar, es un paradigma para estructurar el software de una manera que sea modular, reutilizable y fácil de entender. En un proyecto Spring Boot, aunque el framework nos abstrae de muchas cosas, los principios de la POO son fundamentales para escribir un código limpio y escalable.

Este proyecto se basa en cuatro pilares de la POO:

1.  **Abstracción**
2.  **Encapsulamiento**
3.  **Herencia**
4.  **Polimorfismo**

---

### 1. Abstracción

**¿Qué es?** La abstracción consiste en ocultar los detalles complejos de implementación y exponer solo la funcionalidad esencial. En Java, logramos esto principalmente a través de **interfaces** y **clases abstractas**.

**¿Por qué es útil?**
*   **Desacoplamiento**: El código cliente no depende de una implementación concreta, sino de un "contrato" (la interfaz). Esto nos permite cambiar la implementación sin afectar al resto de la aplicación.
*   **Claridad**: Simplifica el entendimiento del sistema al enfocarse en el "qué" hace un objeto, en lugar del "cómo" lo hace.

**Ejemplo en nuestro proyecto:**

Crearemos una interfaz `UserService` que define las operaciones que se pueden realizar con los usuarios.

```java
// El "contrato" que define QUÉ se puede hacer
public interface UserService {
    User findById(Long id);
    User save(User user);
}
```

Y luego, una clase que implementa esa interfaz. El `UserController` (que usará este servicio) solo conocerá la interfaz, no los detalles de la implementación.

```java
// La implementación que define CÓMO se hace
@Service
public class UserServiceImpl implements UserService {
    // ... Lógica para buscar y guardar usuarios en la BD
}
```

---

### 2. Encapsulamiento

**¿Qué es?** El encapsulamiento es la práctica de agrupar los datos (atributos) y los métodos que operan sobre esos datos dentro de una misma unidad (una clase). Además, restringe el acceso directo a los datos, forzando a que la interacción se realice a través de métodos públicos (`getters` y `setters`).

**¿Por qué es útil?**
*   **Integridad de los datos**: Evita que los datos de un objeto sean modificados de forma inesperada o incorrecta.
*   **Mantenibilidad**: Si la lógica para manipular un dato cambia, solo necesitamos modificarlo dentro de la clase, sin afectar al código que la utiliza.

**Ejemplo en nuestro proyecto:**

Nuestra clase `User` encapsulará sus atributos. Para acceder o modificar el email, se deberán usar sus métodos públicos.

```java
@Entity
public class User {

    @Id
    private Long id;

    private String username;

    @Column(unique = true)
    private String email; // Atributo privado

    // Constructor, otros campos...

    // Método público para acceder al dato
    public String getEmail() {
        return this.email;
    }

    // Método público para modificar el dato con validación
    public void setEmail(String email) {
        if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("Email inválido");
        }
        this.email = email;
    }
}
```

---

### 3. Herencia

**¿Qué es?** La herencia permite que una clase (`clase hija` o `subclase`) adquiera los atributos y métodos de otra clase (`clase padre` o `superclase`). Se usa para crear una jerarquía de "es un/a" (ej: un `Perro` es un `Animal`).

**¿Por qué es útil?**
*   **Reutilización de código**: Evita duplicar código al compartir lógica común en una clase base.
*   **Organización**: Estructura el código de una manera lógica y jerárquica.

**Ejemplo en nuestro proyecto:**

Podríamos tener una clase base `BaseEntity` que contenga campos comunes a todas nuestras entidades, como `id`, `createdAt` y `updatedAt`.

```java
@MappedSuperclass // Indica a JPA que no es una entidad, sino una clase base
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    // Getters y Setters
}
```

Y nuestras entidades, como `User`, heredarían de ella para reutilizar estos campos.

```java
@Entity
public class User extends BaseEntity {
    // Ya no necesita declarar id, createdAt, updatedAt
    private String username;
    // ...
}
```

---

### 4. Polimorfismo

**¿Qué es?** El polimorfismo (del griego, "muchas formas") permite que un objeto de una clase hija sea tratado como si fuera un objeto de su clase padre. Esto se manifiesta principalmente de dos formas:
1.  **Sobrescritura de métodos (Overriding)**: Una subclase proporciona una implementación específica de un método que ya está definido en su superclase.
2.  **Polimorfismo en tiempo de ejecución**: El método que se ejecuta se decide en tiempo de ejecución, dependiendo del tipo real del objeto.

**¿Por qué es útil?**
*   **Flexibilidad**: Permite escribir código genérico que puede trabajar con diferentes tipos de objetos de forma uniforme.
*   **Extensibilidad**: Se pueden añadir nuevas clases hijas que implementen el comportamiento polimórfico sin cambiar el código que las utiliza.

**Ejemplo en nuestro proyecto:**

Imaginemos que tenemos diferentes tipos de notificaciones (`EmailNotification`, `SmsNotification`) que heredan de una clase base `Notification`.

```java
public abstract class Notification {
    public abstract void send(User user, String message);
}

public class EmailNotification extends Notification {
    @Override
    public void send(User user, String message) {
        System.out.println("Enviando email a " + user.getEmail() + ": " + message);
        // Lógica para enviar un email real
    }
}

public class SmsNotification extends Notification {
    @Override
    public void send(User user, String message) {
        System.out.println("Enviando SMS a " + user.getPhoneNumber() + ": " + message);
        // Lógica para enviar un SMS
    }
}
```

Un servicio de notificaciones podría trabajar con cualquier tipo de `Notification` sin saber cuál es concretamente.

```java
public class NotificationService {
    // Este método es polimórfico
    public void sendNotification(Notification notification, User user, String message) {
        notification.send(user, message); // Java decide en tiempo de ejecución qué método send() llamar
    }
}
```
