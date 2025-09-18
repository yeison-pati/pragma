# Guía Profunda sobre Transacciones en Spring y JPA

Una de las responsabilidades más críticas de una aplicación empresarial es garantizar la **integridad de los datos**. Las transacciones son el mecanismo fundamental para lograrlo. En el ecosistema de Spring, `@Transactional` es la herramienta principal para gestionar transacciones de forma declarativa.

## ¿Qué es una Transacción? (ACID)

Una transacción es una única unidad de trabajo que debe completarse en su totalidad o no completarse en absoluto. Se rige por las propiedades **ACID**:

*   **Atomicidad (Atomicity)**: O todo o nada. La transacción se ejecuta por completo o se revierte (rollback) como si nunca hubiera ocurrido.
*   **Consistencia (Consistency)**: La base de datos siempre pasa de un estado válido a otro. Nunca se deja en un estado intermedio o corrupto.
*   **Aislamiento (Isolation)**: Las transacciones concurrentes no deben interferir entre sí. Lo que una transacción hace no es visible para otras hasta que se completa.
*   **Durabilidad (Durability)**: Una vez que una transacción se ha completado (commit), sus cambios son permanentes y sobreviven a cualquier fallo del sistema.

## `@Transactional`: La Magia Declarativa de Spring

La anotación `@Transactional` le dice a Spring que envuelva un método (o todos los métodos de una clase) en un proxy que gestiona el ciclo de vida de una transacción.

*   **Inicio**: Antes de que se ejecute el método, Spring inicia una transacción y la asocia al hilo de ejecución actual.
*   **Éxito (Commit)**: Si el método se completa sin lanzar una `RuntimeException` (o una excepción configurada para rollback), Spring realiza un `commit` de la transacción.
*   **Fallo (Rollback)**: Si el método lanza una `RuntimeException` o un `Error`, Spring realiza un `rollback`, revirtiendo todos los cambios hechos en la base de datos durante la transacción.

**Ejemplo en nuestro `UserServiceImpl`**:

```java
@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;

    // ... constructor ...

    @Override
    @Transactional // Inicia una transacción de lectura/escritura
    public User createUser(User user) {
        // Si userRepository.save() falla, o si hubiera otra operación
        // que lanzara una RuntimeException, la transacción haría rollback.
        return userRepository.save(user);
    }

    @Override
    @Transactional(readOnly = true) // Transacción optimizada para solo lectura
    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }
}
```

### El Atributo `readOnly`

Cuando marcamos una transacción como `readOnly = true`, le damos una pista al proveedor de persistencia (Hibernate) y a la base de datos. Esto puede activar optimizaciones:

1.  **Optimización de Hibernate**: Hibernate puede evitar el "dirty checking" (comprobar si las entidades han cambiado), lo que reduce el consumo de memoria y CPU.
2.  **Optimización del Driver JDBC**: El driver puede indicarle a la base de datos que la transacción es de solo lectura, lo que puede mejorar el rendimiento a nivel de la base de datos.

**Regla de oro**: Usa siempre `@Transactional(readOnly = true)` para cualquier operación que solo lea datos.

---

## Niveles de Propagación (`Propagation`)

¿Qué sucede si un método transaccional llama a otro método transaccional? El comportamiento se define por el nivel de propagación.

`@Transactional(propagation = Propagation.REQUIRED)` es el **valor por defecto** y el más común.

*   **`REQUIRED`**: Si ya existe una transacción, se une a ella. Si no existe, crea una nueva. Es la opción ideal para la mayoría de los casos de servicio.

*   **`REQUIRES_NEW`**: Siempre crea una **nueva transacción independiente**. Suspende la transacción actual si existe una. Es útil para operaciones que deben tener éxito o fracasar de forma independiente a la transacción principal (ej: registrar una auditoría).

*   **`SUPPORTS`**: Si existe una transacción, se une. Si no, se ejecuta sin transacción.

*   **`NOT_SUPPORTED`**: Si existe una transacción, la suspende y se ejecuta sin transacción.

*   **`MANDATORY`**: Requiere que exista una transacción. Si no hay ninguna, lanza una excepción.

*   **`NEVER`**: Requiere que no exista ninguna transacción. Si hay una, lanza una excepción.

*   **`NESTED`**: Inicia una transacción anidada si el gestor de transacciones lo soporta (como JDBC con Savepoints). Si la transacción anidada falla, se puede hacer rollback solo hasta el savepoint, sin invalidar la transacción externa.

**Ejemplo Práctico (`REQUIRES_NEW`)**:

Imagina que quieres registrar cada intento de creación de usuario, incluso si la creación falla.

```java
@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final AuditService auditService; // Un servicio de auditoría

    @Transactional // Transacción principal (T1)
    public User createUser(User user) {
        try {
            // Se une a la transacción T1
            return userRepository.save(user);
        } catch (DataIntegrityViolationException e) {
            // El usuario ya existe, esto causa un rollback en T1
            throw e;
        } finally {
            // Llama a un método con una nueva transacción (T2)
            auditService.logAttempt("CREATE_USER", user.getUsername());
        }
    }
}

@Service
public class AuditServiceImpl implements AuditService {

    private final AuditRepository auditRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW) // Inicia T2
    public void logAttempt(String action, String username) {
        // Esta operación se ejecutará y hará commit en su propia transacción (T2),
        // sin importar si la transacción principal (T1) hace commit o rollback.
        auditRepository.save(new AuditLog(action, username));
    }
}
```

## Niveles de Aislamiento (`Isolation`)

El aislamiento controla hasta qué punto una transacción es visible para otras transacciones concurrentes. Es un equilibrio entre rendimiento y consistencia.

*   **`READ_UNCOMMITTED`**: El más bajo. Permite "lecturas sucias" (dirty reads), donde una transacción puede leer cambios no confirmados de otra. Rápido pero peligroso.
*   **`READ_COMMITTED`**: Evita lecturas sucias. Una transacción solo ve los cambios que han sido confirmados. Es el default en muchas bases de datos (PostgreSQL, Oracle). Puede sufrir de "lecturas no repetibles".
*   **`REPEATABLE_READ`**: Evita lecturas no repetibles. Si una transacción lee una fila, leerá los mismos datos si lo intenta de nuevo. Es el default en MySQL. Puede sufrir de "lecturas fantasma".
*   **`SERIALIZABLE`**: El más alto y restrictivo. Es como si las transacciones se ejecutaran una tras otra. Evita todos los problemas de concurrencia, pero puede ser muy lento.

Puedes configurar el nivel de aislamiento así: `@Transactional(isolation = Isolation.REPEATABLE_READ)`. En general, es mejor dejar el nivel de aislamiento por defecto de tu base de datos a menos que tengas un problema de concurrenૢrencia muy específico que resolver.
