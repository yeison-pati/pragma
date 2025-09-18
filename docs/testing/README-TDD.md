# Guía sobre Desarrollo Guiado por Pruebas (TDD)

El Desarrollo Guiado por Pruebas (TDD, por sus siglas en inglés *Test-Driven Development*) es una práctica de desarrollo de software que invierte el orden tradicional de la programación. En lugar de escribir el código de producción primero y las pruebas después (si es que se escriben), en TDD el ciclo es:

1.  **Escribir una prueba que falla.**
2.  **Escribir el código mínimo para que la prueba pase.**
3.  **Mejorar el código (refactorizar) manteniendo la prueba en verde.**

Este ciclo se conoce como **"Rojo-Verde-Refactor"**.

---

### El Ciclo Rojo-Verde-Refactor

Este ciclo es el corazón de TDD.

#### 1. 🔴 Fase Roja: Escribir una prueba que falla

*   **Objetivo**: Definir claramente qué quieres que haga tu código.
*   **Proceso**:
    1.  Piensa en una pequeña pieza de funcionalidad que quieras añadir (ej: "registrar un nuevo usuario").
    2.  Escribe una prueba unitaria que verifique esa funcionalidad.
    3.  Como todavía no has escrito el código de producción, la prueba **debe fallar**. Si no falla, significa que la prueba no está verificando nada útil o que la funcionalidad ya existe. El fallo esperado suele ser un error de compilación (la clase o el método no existen) o una aserción fallida.

**¿Por qué empezar con una prueba que falla?**
*   **Te obliga a pensar**: Te fuerza a definir los requisitos y la interfaz de tu código (cómo se va a usar) antes de implementarlo.
*   **Garantiza la cobertura**: Asegura que cada línea de código de producción que escribas esté cubierta por al menos una prueba.
*   **Evita falsos positivos**: Si la prueba pasa desde el principio, ¿cómo sabes que realmente fallaría si el código estuviera mal? Verla fallar primero te da la confianza de que está funcionando correctamente.

#### 2. 🟢 Fase Verde: Escribir el código mínimo para que la prueba pase

*   **Objetivo**: Hacer que la prueba pase lo más rápido posible.
*   **Proceso**:
    1.  Escribe **solo el código necesario** para satisfacer la prueba.
    2.  No te preocupes por la elegancia, el rendimiento o el código duplicado. El objetivo es simplemente pasar de rojo a verde. Puedes "engañar" o "hardcodear" valores si es necesario. La única meta es hacer que la barra de pruebas se ponga verde.

**¿Por qué escribir el código "más tonto" posible?**
*   **Enfoque**: Te mantiene enfocado en resolver un solo problema a la vez.
*   **Simplicidad**: Evita la sobreingeniería. Solo escribes el código que los requisitos (representados por la prueba) te exigen.

#### 3. 🔵 Fase de Refactorización: Mejorar el código

*   **Objetivo**: Limpiar el código que acabas de escribir, ahora que tienes una red de seguridad (la prueba).
*   **Proceso**:
    1.  Mejora la implementación: elimina duplicación, mejora los nombres de las variables, extrae métodos, etc.
    2.  **Vuelve a ejecutar la prueba** después de cada pequeño cambio para asegurarte de que no has roto nada. La prueba debe permanecer en verde.

**¿Por qué refactorizar al final?**
*   **Seguridad**: Puedes hacer cambios con la confianza de que si rompes algo, la prueba te lo dirá inmediatamente.
*   **Diseño emergente**: El buen diseño emerge a partir de la refactorización constante, en lugar de intentar planificarlo todo desde el principio.

---

### Beneficios Clave de TDD

1.  **Red de Seguridad**: Las pruebas actúan como una red de seguridad que te permite hacer cambios y refactorizar el código sin miedo a introducir regresiones.
2.  **Mejor Diseño**: TDD te empuja a escribir código desacoplado y modular, porque el código difícil de probar suele ser un síntoma de un mal diseño.
3.  **Documentación Viva**: Las pruebas son la mejor forma de documentación. Describen exactamente cómo se supone que debe funcionar el código y sirven como ejemplos de uso.
4.  **Desarrollo Enfocado**: Te obliga a centrarte en un requisito a la vez, lo que reduce la carga cognitiva y aumenta la productividad.
5.  **Menos Depuración**: Pasas menos tiempo depurando, porque los errores se detectan de inmediato, cuando el cambio que los introdujo todavía está fresco en tu mente.

En los siguientes pasos, aplicaremos este ciclo para construir nuestro `UserService`. Empezaremos creando una prueba para un método que aún no existe.
