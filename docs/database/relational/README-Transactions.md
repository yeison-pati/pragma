# Guía sobre Transacciones en Spring con @Transactional

En el mundo de las bases de datos, una transacción es una secuencia de operaciones que se ejecutan como un único bloque de trabajo lógico. O todo el bloque tiene éxito, o nada de ello se aplica. Esto garantiza la integridad y consistencia de los datos.

Las transacciones se rigen por las propiedades **ACID**:

*   **A - Atomicidad (Atomicity)**: La transacción es "todo o nada". Si una operación falla, toda la transacción se revierte (`rollback`).
*   **C - Consistencia (Consistency)**: La transacción lleva a la base de datos de un estado válido a otro. Nunca la deja en un estado intermedio o inválido.
*   **I - Aislamiento (Isolation)**: Las transacciones concurrentes no deben interferir entre sí. Es como si cada transacción se ejecutara en una "burbuja" aislada.
*   **D - Durabilidad (Durability)**: Una vez que una transacción se ha completado con éxito (`commit`), sus cambios son permanentes y sobreviven a cualquier fallo del sistema.

---

### ¿Cómo gestiona Spring las transacciones?

Spring simplifica enormemente la gestión de transacciones a través de la **programación orientada a aspectos (AOP)** y la anotación `@Transactional`.

Cuando anotas un método (o una clase entera) con `@Transactional`, Spring crea un "proxy" alrededor de tu bean. Este proxy se encarga de:
1.  **Iniciar una transacción** justo antes de que se ejecute tu método.
2.  **Hacer `commit`** de la transacción si el método se completa con éxito.
3.  **Hacer `rollback`** de la transacción si el método lanza una `RuntimeException` (o cualquier `Error`). Por defecto, las `Exception` chequeadas (checked exceptions) NO provocan un rollback.

### Ejemplo Práctico

Imagina un servicio que debe registrar un usuario y, al mismo tiempo, crearle un perfil inicial. Ambas operaciones deben tener éxito. Si la creación del perfil falla, no queremos que el usuario quede registrado a medias.

**1. El Servicio:**

Anotamos el método `registerUserWithProfile` con `@Transactional`.

```java
// UserService.java

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    // ... constructor

    @Transactional // <-- La magia está aquí
    public User registerUserWithProfile(String username, String email, String bio) {
        // 1. Crear y guardar el usuario
        User newUser = User.builder()
                .username(username)
                .email(email)
                .password("default-password") // En un caso real, esto estaría hasheado
                .build();
        User savedUser = userRepository.save(newUser);

        // 2. Simular un error en la creación del perfil
        if (bio == null || bio.isEmpty()) {
            throw new IllegalArgumentException("La biografía no puede ser nula o vacía");
        }

        // 3. Crear y guardar el perfil
        UserProfile profile = UserProfile.builder()
                .user(savedUser)
                .bio(bio)
                .build();
        userProfileRepository.save(profile);

        return savedUser;
    }
}
```

**2. El Comportamiento:**

*   **Caso de éxito**: Si llamamos a `registerUserWithProfile("test", "test@test.com", "Mi bio")`, ambas entidades (`User` y `UserProfile`) se guardarán en la base de datos. La transacción hará `commit` al final del método.

*   **Caso de fallo**: Si llamamos a `registerUserWithProfile("test2", "test2@test.com", null)`, el método lanzará una `IllegalArgumentException`. Como esta es una `RuntimeException`, Spring interceptará la excepción y hará `rollback` de la transacción. **El usuario "test2" NO quedará guardado en la base de datos**, manteniendo así la consistencia.

### Puntos Clave a Recordar sobre `@Transactional`

*   **Debe ser `public`**: Solo funciona en métodos públicos. Spring no puede aplicar el proxy a métodos privados, protegidos o de paquete.
*   **Llamadas internas**: Si un método sin `@Transactional` dentro de la misma clase llama a otro método con `@Transactional`, la transacción **NO se iniciará**. Esto ocurre porque la llamada no pasa por el proxy de Spring. Es una llamada `this.myTransactionalMethod()`.
*   **Propagación**: Puedes configurar cómo se comporta una transacción si ya existe otra en curso (usando `propagation`). El valor por defecto es `REQUIRED`, que se une a una transacción existente o crea una nueva si no hay ninguna.
*   **Solo `RuntimeException`**: Por defecto, solo las excepciones no chequeadas (`RuntimeException` y `Error`) activan el rollback. Puedes cambiar este comportamiento con `rollbackFor` (ej: `@Transactional(rollbackFor = Exception.class)`).
*   **Read-Only**: Para operaciones que solo leen datos (como `findById`), es una buena práctica usar `@Transactional(readOnly = true)`. Esto le da una pista al proveedor de persistencia para aplicar optimizaciones.
