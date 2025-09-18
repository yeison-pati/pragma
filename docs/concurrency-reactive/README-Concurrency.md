# Guía sobre Concurrencia y Paralelismo en Java

En el desarrollo de software moderno, es fundamental entender cómo gestionar múltiples tareas para construir aplicaciones eficientes y que respondan rápidamente. Aquí es donde entran los conceptos de concurrencia y paralelismo.

---

### Concurrencia vs. Paralelismo

Aunque a menudo se usan indistintamente, no son lo mismo.

*   **Concurrencia (Concurrency)**: Es la capacidad de un sistema para **gestionar** múltiples tareas al mismo tiempo. Las tareas pueden empezar, ejecutarse e completarse en períodos de tiempo superpuestos. No significa que se ejecuten en el mismo instante. En un procesador de un solo núcleo, la concurrencia se logra cambiando de contexto (`context switching`) muy rápidamente entre tareas, dando la **ilusión** de que se ejecutan a la vez.
    *   **Analogía**: Un cocinero que prepara varios platos a la vez. Pone a hervir el agua para la pasta, mientras corta las verduras para la ensalada y luego revisa el horno. Está gestionando varias tareas, pero en cada instante solo hace una cosa.

*   **Paralelismo (Parallelism)**: Es la capacidad de un sistema para **ejecutar** múltiples tareas simultáneamente. Esto solo es posible si se dispone de múltiples recursos de cómputo, como un procesador multi-núcleo.
    *   **Analogía**: Un equipo de tres cocineros. Uno hierve la pasta, otro corta las verduras y el tercero prepara la salsa, todo al mismo tiempo. El trabajo se completa más rápido porque las tareas se ejecutan en paralelo.

**En resumen:** La concurrencia es sobre **gestionar** muchas cosas a la vez. El paralelismo es sobre **hacer** muchas cosas a la vez. El paralelismo es una forma de lograr la concurrencia.

### ¿Cuándo elegir uno u otro?

*   **Elige Concurrencia** cuando tienes tareas que implican mucha espera, como operaciones de I/O (entrada/salida): leer un archivo, hacer una petición a una API externa, consultar una base de datos. Mientras una tarea está esperando la respuesta de la red, el procesador puede dedicarse a otra tarea. El modelo tradicional de Spring Boot (un hilo por petición) es un modelo concurrente.

*   **Elige Paralelismo** cuando tienes tareas que son computacionalmente intensivas (CPU-bound), como procesar una imagen, encriptar datos o realizar cálculos matemáticos complejos. En estos casos, dividir la tarea y ejecutarla en múltiples núcleos acelera el tiempo total de ejecución.

---

### Ejemplo con la API de Concurrencia de Java

Java proporciona una potente API para manejar la concurrencia en el paquete `java.util.concurrent`. La pieza central es el `ExecutorService`, que gestiona un pool de hilos (`ThreadPool`) para ejecutar tareas de forma asíncrona.

A continuación, un ejemplo práctico que simula el procesamiento de varias órdenes de compra de forma concurrente.

**Escenario**: Tenemos un servicio que recibe una lista de IDs de órdenes y debe procesar cada una (simulado con un `Thread.sleep`). En lugar de procesarlas una por una (secuencialmente), usaremos un `ExecutorService` para procesarlas concurrentemente.

**1. El Servicio `OrderProcessingService`**

Este servicio no será un bean de Spring, es un ejemplo autocontenido para demostrar el uso de la API de Java.

```java
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class OrderProcessingService {

    // Creamos un pool con un número fijo de hilos.
    // Usar el número de núcleos disponibles es una buena práctica para tareas CPU-bound.
    // Para tareas I/O-bound, el número puede ser mayor.
    private final ExecutorService executor = Executors.newFixedThreadPool(
            Runtime.getRuntime().availableProcessors()
    );

    public void processOrders(List<Long> orderIds) {
        System.out.println("Iniciando procesamiento de " + orderIds.size() + " órdenes...");
        long startTime = System.currentTimeMillis();

        for (Long orderId : orderIds) {
            // 'submit' envía la tarea al pool de hilos para su ejecución.
            // La tarea es una expresión lambda que implementa la interfaz 'Runnable'.
            executor.submit(() -> processSingleOrder(orderId));
        }

        // Es crucial apagar el ExecutorService cuando ya no se necesita.
        shutdownExecutor();

        long endTime = System.currentTimeMillis();
        System.out.println("Todas las órdenes han sido enviadas para procesar en " + (endTime - startTime) + " ms.");
    }

    private void processSingleOrder(long orderId) {
        try {
            System.out.println("Procesando orden " + orderId + " en el hilo: " + Thread.currentThread().getName());
            // Simulamos una tarea que consume tiempo, como llamar a otro servicio o una consulta a BD.
            Thread.sleep(1000);
            System.out.println("Orden " + orderId + " procesada.");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void shutdownExecutor() {
        // 'shutdown()' espera a que las tareas encoladas terminen, pero no acepta nuevas.
        executor.shutdown();
        try {
            // 'awaitTermination' bloquea hasta que todas las tareas hayan completado su ejecución
            // o hasta que ocurra el timeout. Es una buena práctica para asegurar que todo termina.
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                // Si las tareas no terminan en 60 segundos, forzamos el apagado.
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        OrderProcessingService service = new OrderProcessingService();
        List<Long> orders = List.of(101L, 102L, 103L, 104L, 105L, 106L, 107L, 108L);
        service.processOrders(orders);
    }
}
```

**¿Cómo ejecutar este ejemplo?**
Puedes copiar este código en un archivo `.java`, compilarlo (`javac`) y ejecutarlo (`java`).

**Salida esperada:**
Notarás que las órdenes no se procesan en orden secuencial (101, 102, ...). Varios hilos del pool las tomarán y las procesarán concurrentemente. El tiempo total de ejecución será mucho menor que la suma de los tiempos individuales (8 segundos). Si tienes 4 núcleos, el tiempo será cercano a 2 segundos. Esto demuestra el poder de la concurrencia.
