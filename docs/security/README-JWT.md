# Guía sobre Seguridad de API con JSON Web Tokens (JWT)

Proteger una API es uno de los aspectos más críticos del desarrollo backend. En este proyecto, hemos implementado un sistema de autenticación basado en **JSON Web Tokens (JWT)**, que es el estándar de facto para APIs REST modernas y stateless.

---

### ¿Qué es un JWT?

Un JWT es un estándar abierto (RFC 7519) que define una forma compacta y autónoma de transmitir información de forma segura entre partes como un objeto JSON. La información puede ser verificada y confiada porque está **firmada digitalmente**.

Un JWT consta de tres partes separadas por puntos (`.`):

1.  **Header (Cabecera)**
2.  **Payload (Carga útil)**
3.  **Signature (Firma)**

Un token tiene esta apariencia: `xxxxx.yyyyy.zzzzz`

#### 1. Header

La cabecera típicamente consiste en dos partes: el tipo de token (`JWT`) y el algoritmo de firma que se está utilizando, como HMAC SHA256 o RSA.

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```
Esta cabecera se codifica en **Base64Url** para formar la primera parte del JWT.

#### 2. Payload

El payload contiene las "reclamaciones" (claims). Los claims son declaraciones sobre una entidad (normalmente, el usuario) y datos adicionales. Hay tres tipos de claims:

*   **Registered claims**: Un conjunto de claims predefinidos que no son obligatorios pero se recomiendan, como `iss` (emisor), `exp` (tiempo de expiración), `sub` (asunto, ej: el ID o username del usuario).
*   **Public claims**: Claims definidos por quienes usan los JWTs, pero para evitar colisiones deben ser definidos en el Registro de IANA JSON Web Token o ser URI.
*   **Private claims**: Claims personalizados creados para compartir información entre partes que acuerdan usarlos.

```json
{
  "sub": "testuser",
  "iat": 1678886400,
  "exp": 1678972800
}
```
El payload también se codifica en **Base64Url** para formar la segunda parte del JWT.

#### 3. Signature

Para crear la firma, se toman la cabecera codificada, el payload codificado, un **secreto** (una clave secreta), el algoritmo especificado en la cabecera, y se firma todo.

```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  tu-clave-secreta
)
```
La firma se utiliza para **verificar que el mensaje no ha sido alterado** en el camino. Si alguien intenta cambiar el payload (por ejemplo, cambiar su `sub` a "admin"), la firma ya no será válida.

---

### ¿Por qué JWT en lugar de Sesiones Tradicionales?

Las sesiones basadas en servidor han sido el pilar de la autenticación web durante años, pero tienen desventajas en arquitecturas modernas.

| Característica        | Sesiones Tradicionales (Stateful)                               | JWT (Stateless)                                                 |
|-----------------------|-----------------------------------------------------------------|-----------------------------------------------------------------|
| **Estado**            | El estado de la sesión se almacena en el servidor.              | El estado se almacena en el cliente (dentro del token).         |
| **Escalabilidad**     | Difícil de escalar horizontalmente. Requiere sesiones pegajosas (sticky sessions) o un almacenamiento de sesión compartido (Redis, etc.). | **Fácil de escalar**. Cualquier servidor con el secreto puede validar el token. |
| **Rendimiento**       | Requiere una consulta a la base de datos/caché en cada petición para validar la sesión. | La validación es computacional (verificar la firma). No requiere I/O. |
| **Acoplamiento**      | Acopla al cliente con el servidor. No es ideal para aplicaciones móviles o SPAs (Single Page Applications). | **Desacoplado**. Funciona perfectamente con cualquier tipo de cliente (web, móvil, otro servicio). |
| **Seguridad (CSRF)**  | Vulnerable a ataques CSRF si no se protege con tokens anti-CSRF. | No vulnerable a CSRF porque el token no se envía automáticamente en las cookies. Se envía en la cabecera `Authorization`. |

**En resumen, JWT es ideal para sistemas distribuidos, microservicios y cualquier arquitectura donde la escalabilidad y el desacoplamiento son importantes.**

---

### Flujo de Autenticación en Nuestro Proyecto

1.  **Registro (`POST /api/auth/register`)**:
    *   Un usuario envía su `username`, `email` y `password`.
    *   El `AuthenticationService` valida que no existan duplicados.
    *   La contraseña se **hashea** con `BCryptPasswordEncoder`.
    *   El nuevo `User` se guarda en la base de datos.
    *   Se genera un JWT para el nuevo usuario y se devuelve en la respuesta.

2.  **Login (`POST /api/auth/login`)**:
    *   El usuario envía su `username` y `password`.
    *   El `AuthenticationManager` de Spring Security valida las credenciales. Compara el hash de la contraseña enviada con el hash almacenado en la base de datos.
    *   Si la autenticación es exitosa, el `AuthenticationService` genera un nuevo JWT.
    *   El token se devuelve al cliente.

3.  **Acceso a Rutas Protegidas (ej: `GET /api/users/me`)**:
    *   El cliente debe incluir el JWT en la cabecera `Authorization` de la petición: `Authorization: Bearer <token>`.
    *   Nuestro filtro personalizado, `JwtAuthenticationFilter`, intercepta la petición.
    *   Extrae el token y lo valida usando `JwtService` (comprueba la firma y la fecha de expiración).
    *   Si el token es válido, extrae el `username`, carga los datos del usuario (`UserDetails`) desde la base de datos.
    *   Crea un objeto `Authentication` y lo establece en el `SecurityContextHolder`. A partir de este punto, Spring Security considera al usuario como autenticado para esta petición.
    *   La petición continúa hacia el controlador. Si el token no es válido, el filtro no hace nada y el usuario permanece anónimo, por lo que Spring Security denegará el acceso.
