# Guía de Caching de Alto Rendimiento con Redis

El **caching** es una de las técnicas más efectivas para mejorar el rendimiento y la escalabilidad de una aplicación. Consiste en almacenar temporalmente los resultados de operaciones costosas (como consultas a la base de datos) en una memoria de acceso rápido.

**Redis** es una base de datos en memoria extremadamente rápida y versátil, comúnmente utilizada como caché distribuida en sistemas de microservicios.

### ¿Por Qué Usar una Caché?

1.  **Reducción de Latencia**: Acceder a datos desde Redis (en memoria) es órdenes de magnitud más rápido que acceder a ellos desde un disco de base de datos (PostgreSQL, MongoDB). Esto se traduce en respuestas de API más rápidas.
2.  **Reducción de la Carga de la Base de Datos**: Al servir las solicitudes de lectura desde la caché, se reduce drásticamente el número de consultas a la base de datos principal. Esto protege a la base de datos de la sobrecarga y reduce costos.
3.  **Mejora de la Disponibilidad**: Si la base de datos principal sufre una interrupción temporal, la aplicación puede seguir funcionando para las solicitudes de lectura cuyos datos ya están en la caché.

---

### Implementación con Spring Boot Cache

Spring Boot proporciona una potente abstracción de caché que nos permite añadir caching a nuestra aplicación con un esfuerzo mínimo y sin acoplar nuestro código a un proveedor de caché específico.

#### 1. Habilitar el Caching

El primer paso es habilitar la gestión de caché en nuestra aplicación principal con la anotación `@EnableCaching`.

```java
// En UserServiceApplication.java y OrderServiceApplication.java
@SpringBootApplication
@EnableCaching
public class UserServiceApplication {
    // ...
}
```

#### 2. Configurar Redis como Proveedor

En `application.properties`, le decimos a Spring Boot que use Redis y configuramos su comportamiento:

```properties
# Tell Spring Boot to use Redis for caching
spring.cache.type=redis

# Connection details for Redis
spring.data.redis.host=localhost
spring.data.redis.port=6379

# Default Time-To-Live (TTL) for all cache entries
# Aquí, 10 minutos. Después de este tiempo, la entrada es invalidada.
spring.cache.redis.time-to-live=600000

# Usar un prefijo para evitar colisiones de claves en Redis
spring.cache.redis.key-prefix=user-service::
```

#### 3. Anotaciones de Caching

Spring nos ofrece varias anotaciones para gestionar el ciclo de vida de la caché.

##### `@Cacheable`

Esta es la anotación principal para las operaciones de lectura. Le dice a Spring: "Antes de ejecutar este método, revisa la caché. Si encuentras una entrada con esta clave, devuélvela inmediatamente sin ejecutar el método. Si no, ejecuta el método, guarda el resultado en la caché y luego devuélvelo".

**Ejemplo en `UserServiceImpl`**:

```java
@Service
@Slf4j
public class UserServiceImpl implements UserService {
    // ...
    @Override
    @Transactional(readOnly = true)
    @Cacheable(value = "users", key = "#id") // 'users' es el nombre de la caché, #id es la clave
    public Optional<User> getUserById(Long id) {
        log.info("--- Database Hit: Fetching user with id {} from database. ---", id);
        return userRepository.findById(id);
    }
}
```

La primera vez que se llame a `getUserById(1L)`, se verá el mensaje de log "Database Hit". Las siguientes veces que se llame con el mismo ID (mientras la entrada no expire), el log no aparecerá, y la respuesta será mucho más rápida.

##### `@CachePut`

A veces queremos actualizar una entrada en la caché sin interferir con la ejecución del método. `@CachePut` **siempre** ejecuta el método y luego actualiza la caché con el resultado. Es útil para operaciones de actualización (HTTP `PUT`).

**Ejemplo hipotético**:

```java
@Override
@Transactional
@CachePut(value = "users", key = "#user.id") // Actualiza la caché con el nuevo estado del usuario
public User updateUser(User user) {
    // Lógica para actualizar el usuario...
    return userRepository.save(user);
}
```

##### `@CacheEvict`

Esta anotación se utiliza para eliminar (invalidar) entradas de la caché. Es fundamental para operaciones de borrado (HTTP `DELETE`) para evitar que la caché sirva datos obsoletos.

**Ejemplo hipotético**:

```java
@Override
@Transactional
@CacheEvict(value = "users", key = "#id") // Elimina la entrada de la caché
public void deleteUser(Long id) {
    userRepository.deleteById(id);
}
```

También puedes usar `allEntries = true` para vaciar una caché completa: `@CacheEvict(value = "users", allEntries = true)`.

Al combinar estas anotaciones, puedes implementar una estrategia de caching completa y robusta que mejora significativamente el rendimiento de la aplicación.
