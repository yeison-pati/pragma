# Guía sobre Carga Perezosa (Lazy) vs. Carga Ansiosa (Eager)

Cuando JPA/Hibernate carga una entidad desde la base de datos, tiene que decidir si carga también todas las entidades relacionadas con ella. Esta decisión se controla mediante las **estrategias de carga (Fetch Strategies)**. Las dos principales son `FetchType.LAZY` y `FetchType.EAGER`.

Entender la diferencia es **crucial** para el rendimiento de cualquier aplicación que use un ORM.

---

### FetchType.EAGER (Carga Ansiosa)

*   **¿Qué hace?**: Cuando se carga una entidad, **inmediatamente se cargan también todas sus relaciones** marcadas como EAGER. Hibernate ejecuta una única consulta SQL (usando un `JOIN`) para traer todos los datos de una vez.
*   **Comportamiento por defecto**:
    *   `@OneToOne`: EAGER
    *   `@ManyToOne`: EAGER
*   **Ventajas**:
    *   **Simple**: No hay que preocuparse por excepciones `LazyInitializationException`. Los datos relacionados siempre están ahí.
*   **Desventajas**:
    *   **Pobre rendimiento**: Es la causa más común de problemas de rendimiento con JPA. Carga muchos más datos de los que probablemente necesitas. Imagina cargar un `User` y que eso desencadene la carga de sus 500 `Orders`, aunque solo querías mostrar el nombre del usuario.
    *   **Ineficiente**: Genera consultas SQL muy grandes y complejas que pueden ser lentas.

### FetchType.LAZY (Carga Perezosa)

*   **¿Qué hace?**: Cuando se carga una entidad, **NO se cargan sus relaciones** marcadas como LAZY. En su lugar, Hibernate coloca un "proxy" (un objeto sustituto). La consulta a la base de datos para cargar los datos relacionados solo se dispara **cuando se accede por primera vez a esa relación** (ej: `user.getOrders()`).
*   **Comportamiento por defecto**:
    *   `@OneToMany`: LAZY
    *   `@ManyToMany`: LAZY
*   **Ventajas**:
    *   **Eficiente**: Carga solo los datos que necesitas, cuando los necesitas. Evita consultas innecesarias y pesadas.
    *   **Mejor rendimiento**: Reduce drásticamente el tiempo de carga inicial de las entidades.
*   **Desventajas**:
    *   **`LazyInitializationException`**: Este es el problema más común. Ocurre si intentas acceder a una relación LAZY fuera del ámbito de una transacción (`@Transactional`). Cuando la sesión de Hibernate se cierra (normalmente al salir del método del servicio), el proxy ya no puede conectarse a la base de datos para cargar los datos.

---

### Ejemplo Práctico: `User` y `UserProfile`

En nuestro proyecto, hemos modelado una relación `@OneToOne` entre `User` y `UserProfile`.

```java
// UserProfile.java
@OneToOne(fetch = FetchType.LAZY) // <-- ¡LAZY!
@MapsId
@JoinColumn(name = "user_id")
private User user;

// User.java
@OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY) // <-- ¡LAZY!
private UserProfile userProfile;
```

**Buena práctica:** **Siempre usa `LAZY` para todas las relaciones (`@OneToOne`, `@ManyToOne` incluidas) y carga los datos explícitamente cuando los necesites.**

### ¿Cómo manejar las relaciones LAZY correctamente?

Si necesitas los datos de una relación LAZY, tienes varias opciones para evitar la `LazyInitializationException`:

**1. La solución incorrecta: `open-in-view = true`**
   Spring Boot viene con la propiedad `spring.jpa.open-in-view` a `true` por defecto. Esto mantiene la sesión de Hibernate abierta hasta que la vista se renderiza, evitando la excepción. **Es una mala práctica y debe desactivarse (`false`)**. Oculta los problemas de rendimiento (problema N+1) y es un antipatrón.

**2. Solución correcta: Usar un `JOIN FETCH` en una consulta**
   Puedes instruir a JPA para que cargue una relación específica en una consulta concreta usando `JOIN FETCH`.

   ```java
   // UserRepository.java
   @Query("SELECT u FROM User u JOIN FETCH u.userProfile WHERE u.id = :id")
   Optional<User> findByIdWithProfile(@Param("id") Long id);
   ```
   Cuando llames a este método, Hibernate ejecutará una única consulta que traerá tanto el `User` como el `UserProfile`, resolviendo el problema de forma eficiente.

**3. Solución correcta: Usar `EntityGraph`**
   Es una forma más avanzada y flexible de definir qué relaciones cargar.

   ```java
   // UserRepository.java
   @EntityGraph(attributePaths = {"userProfile"})
   Optional<User> findById(Long id); // Spring Data JPA sobreescribe el findById para usar el EntityGraph
   ```

**4. Solución (a veces aceptable): Acceder dentro de una transacción**
   Si accedes a la relación LAZY dentro de un método marcado con `@Transactional`, funcionará, porque la sesión de Hibernate todavía está abierta.

   ```java
   @Service
   public class UserService {
       @Transactional
       public String getUserBio(Long userId) {
           User user = userRepository.findById(userId).orElseThrow();
           // Esto funciona porque la sesión está activa.
           // PERO, genera una consulta adicional (problema N+1 si se hace en un bucle).
           return user.getUserProfile().getBio();
       }
   }
   ```
   Esta solución es simple pero puede llevar al **problema N+1**: si haces esto para N usuarios en un bucle, ejecutarás 1 consulta para los usuarios + N consultas para sus perfiles. El `JOIN FETCH` es casi siempre superior.

### Conclusión

| Estrategia | Cuándo usarla                                      | Ventajas                               | Desventajas                                     |
|------------|----------------------------------------------------|----------------------------------------|-------------------------------------------------|
| **EAGER**  | **Casi nunca.** Quizás para un campo muy pequeño y que siempre se usa. | Simple, sin `LazyInitializationException` | **Pésimo rendimiento**, carga datos innecesarios. |
| **LAZY**   | **Casi siempre.** Es la opción por defecto recomendada. | **Eficiente**, carga solo lo necesario. | Requiere manejo explícito (`JOIN FETCH`), riesgo de `LazyInitializationException`. |
