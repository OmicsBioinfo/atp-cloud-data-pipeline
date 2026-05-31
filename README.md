# 🎾 Análisis Estadístico de la ATP en la Nube (Siglo 21)

Este proyecto consiste en la implementación de un **Pipeline de Datos** para migrar, procesar y visualizar un dataset histórico de tenis de ~75 MB.
Los datos fueron alojados en un servidor remoto de **MySQL administrado en la nube (Aiven)**, optimizados mediante consultas SQL y consumidos 
en un **Dashboard Analítico interactivo** en **Looker Studio**.

## 🚀 Acceso al Dashboard
👉 [**Ver Dashboard en Looker Studio**](https://datastudio.google.com/u/0/reporting/ebd62cbe-af3f-48c3-86f6-dde139dc72a0/page/uPpzF)

---

## 📊 Evidencia del Despliegue en la Nube (Cloud Proof)
Para demostrar la integración real con servicios Cloud, se adjuntan las capturas del estado del servidor y la conexión remota en la carpeta `img/`:

### 1. Servidor MySQL Activo en Aiven Cloud
![Estado del Servicio en Aiven](img/captura_aiven_dashboard.png)

### 2. Conexión Remota desde MySQL Workbench
![Conexión Workbench a Cloud](img/captura_workbench_cloud.png)

### 3. Dashboard Final en Looker Studio
![Dashboard Terminado](img/captura_dashboard_terminado.png)

---

## ☁️ Flujo y Conectividad de los Datos

El proyecto descarta el uso de almacenamiento local para la reportería, simulando un entorno de disponibilidad global de la información:

```
[ Dataset ATP (~75MB) ] 
       │
       ▼ (Importación remota via cliente SQL)
[ Servidor MySQL en Aiven Cloud ] ◄─────► [ MySQL Workbench (Modelado de Vistas) ]
       │
       ▼ (Conexión directa por conector MySQL)
[ Looker Studio Dashboard ]
```

* **Aiven:** Aloja de manera centralizada la base de datos relacional, permitiendo credenciales de acceso externas y seguras.
* **MySQL Workbench:** Funciona como el puente para estructurar las tablas, tipos de datos y ejecutar los scripts de optimización directo en el servidor remoto.
* **Looker Studio:** Se conecta mediante el driver nativo de MySQL apuntando al Host de Aiven, procesando y renderizando los datos directamente desde la nube.

---

## 🛠️ Stack Tecnológico
* **Cloud Database:** Aiven (Managed MySQL).
* **Gestor de BD:** MySQL Server / MySQL Workbench.
* **Visualización:** Looker Studio.
* **Estructura:** Scripts SQL de optimización y procesamiento alojados en la carpeta `/sql`.

---

## 💡 Criterios de Optimización Aplicados
Para evitar que Looker Studio realizara consultas pesadas a la tabla cruda de 75 MB (lo que ralentizaría el tablero y aumentaría innecesariamente el 
consumo del servidor en la nube), toda la lógica de negocio se transformó en **Vistas (VIEW)** dentro de MySQL. De este modo, el servidor cloud
pre-calcula las agregaciones de los Aces, las efectividades por superficie y los conteos de títulos, entregándole a Looker Studio datos ya procesados y 
listos para pintar de forma fluida.

---

## 📊 Fuente de Datos (Data Source)
* El dataset original corresponde al histórico oficial de partidos de la ATP.
* Por buenas prácticas de almacenamiento, el archivo plano de datos no se incluye en este repositorio. Puede ser obtenido directamente de la fuente abierta en:
`[Pega aquí el enlace de la fuente original]`.
