# Guía de Infraestructura como Código (IaC) con Terraform para Microservicios

Esta guía explica cómo desplegar nuestra aplicación de microservicios en AWS utilizando Terraform. Hemos diseñado la infraestructura para que sea **moderna, escalable y segura**, siguiendo las mejores prácticas de la industria.

La **Infraestructura como Código (IaC)** es la práctica de gestionar y provisionar infraestructura a través de código, en lugar de hacerlo manualmente. Esto nos da automatización, versionado y consistencia.

---

## Arquitectura de Despliegue: ECS Fargate, la Elección Moderna

Para desplegar nuestros microservicios (`user-service` y `order-service`), hemos elegido **Amazon ECS (Elastic Container Service) con el tipo de lanzamiento Fargate**.

### ¿Por Qué ECS Fargate y no EC2?

El usuario preguntó sobre desplegar en dos servidores EC2 diferentes. Si bien eso es posible, es un enfoque tradicional que conlleva una gran carga de gestión:

*   **Gestión de Servidores**: Con EC2, eres responsable de parchear el sistema operativo, gestionar la seguridad, instalar el runtime de Docker, etc.
*   **Escalado Complejo**: Escalar requiere configurar Auto Scaling Groups para las instancias EC2, lo cual es complejo.
*   **Baja Utilización**: A menudo terminas pagando por capacidad de cómputo que no utilizas.

**ECS Fargate es una solución "Serverless" para contenedores**:

*   **Sin Servidores que Gestionar**: AWS se encarga de toda la infraestructura subyacente. Nosotros solo definimos nuestro contenedor, sus requisitos de CPU/memoria y cómo debe exponerse a la red.
*   **Escalado Sencillo**: Podemos aumentar o disminuir el número de tareas (instancias de nuestros contenedores) con un solo cambio de configuración.
*   **Seguridad Integrada**: Se integra de forma nativa con las redes y la seguridad de AWS.
*   **Pago por Uso**: Solo pagas por la CPU y memoria que tus contenedores consumen mientras se ejecutan.

En resumen, **ECS Fargate nos permite centrarnos en nuestra aplicación, no en la infraestructura**, lo que lo convierte en la opción superior para desplegar microservicios en contenedores en AWS.

---

### Estructura Modular de Terraform

Nuestro código de Terraform es modular para facilitar su comprensión y reutilización.

```
infrastructure/
├── modules/
│   ├── vpc/         # Módulo para la red (VPC, subnets, etc.)
│   ├── ecr/         # Módulo para los registros de contenedores (ECR)
│   ├── alb/         # Módulo para el Application Load Balancer
│   └── ecs/         # Módulo para el clúster, tareas y servicios de ECS
├── main.tf          # Orquesta todos los módulos
├── variables.tf     # Variables de entrada (ej: nombre del proyecto)
├── outputs.tf       # Salidas del despliegue (ej: URL del ALB)
└── providers.tf     # Configuración del proveedor de nube (AWS)
```

### Componentes Desplegados en AWS

1.  **VPC (Virtual Private Cloud)**: Una red virtual aislada para nuestros recursos.
2.  **ECR (Elastic Container Registry)**: Dos repositorios privados, uno para la imagen Docker del `user-service` y otro para el `order-service`.
3.  **ALB (Application Load Balancer)**: Nuestro punto de entrada público. Escucha en el puerto 80 y enruta el tráfico basado en la ruta de la URL:
    *   Las peticiones a `/api/v1/users/*` se envían al `user-service`.
    *   Las peticiones a `/api/v1/orders/*` se envían al `order-service`.
4.  **ECS (Elastic Container Service)**:
    *   Un **Clúster ECS** que agrupa lógicamente nuestros servicios.
    *   Dos **Definiciones de Tareas** (Task Definitions), una para cada microservicio, que describen qué imagen de Docker usar, cuánta CPU/memoria necesita y las variables de entorno.
    *   Dos **Servicios ECS** que se encargan de ejecutar y mantener el número deseado de instancias de cada tarea y conectarlas al ALB.
5.  **Security Groups**: Actúan como firewalls virtuales para controlar el tráfico entre el ALB y los servicios de ECS.
6.  **(Opcional - Próximos Pasos)**: Para un entorno de producción real, también provisionaríamos **Amazon RDS** para PostgreSQL, **Amazon DocumentDB** para MongoDB y **Amazon MSK** para Kafka, en lugar de ejecutarlos en contenedores. Este Terraform puede ser extendido para ello.

---

### 🚀 Cómo Desplegar

**Pre-requisitos**:
*   Tener instalado [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) y el [AWS CLI](https://aws.amazon.com/cli/).
*   Tener configuradas las credenciales de AWS (`aws configure`).
*   Tener instalado [Docker](https://www.docker.com/get-started).

**Paso 1: Construir y Publicar las Imágenes Docker**

Antes de ejecutar Terraform, necesitas construir las imágenes de tus servicios y subirlas a los repositorios de ECR que Terraform creará.

1.  **Despliega la Infraestructura Inicial (para crear los repos ECR)**:
    ```bash
    cd infrastructure
    terraform init
    terraform apply
    ```
    Al final, Terraform te dará las URLs de los repositorios ECR en sus salidas.

2.  **Autentica Docker con ECR**:
    ```bash
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
    ```

3.  **Construye, Etiqueta y Sube cada imagen**:
    ```bash
    # Para user-service
    cd ../user-service
    docker build -t <ECR_REPO_URL_USER_SERVICE>:latest .
    docker push <ECR_REPO_URL_USER_SERVICE>:latest

    # Para order-service
    cd ../order-service
    docker build -t <ECR_REPO_URL_ORDER_SERVICE>:latest .
    docker push <ECR_REPO_URL_ORDER_SERVICE>:latest
    ```

**Paso 2: Desplegar la Aplicación en ECS**

Ahora que las imágenes están en ECR, puedes volver a ejecutar Terraform para que cree los servicios de ECS que las utilizan.

```bash
cd ../infrastructure
terraform apply
```

Terraform detectará que los servicios ECS necesitan ser creados y los desplegará. Al finalizar, la salida `alb_dns_name` te dará la URL pública de tu aplicación.

Para destruir toda la infraestructura y evitar costos, ejecuta:
```bash
terraform destroy
```
