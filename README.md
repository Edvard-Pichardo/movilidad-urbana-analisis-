# Sistema de Análisis de Movilidad Urbana y Transporte

![MySQL](https://img.shields.io/badge/MySQL-5.7%2B-blue)
![InnoDB](https://img.shields.io/badge/Engine-InnoDB-orange)
![Licencia](https://img.shields.io/badge/License-MIT-green)

## Descripción

Base de datos relacional completa para una plataforma de movilidad urbana (similar a Uber, DiDi o Cabify). El proyecto incluye:

- Diseño normalizado con integridad referencial.
- Datos de prueba simulando 4 meses de operación real (junio–septiembre 2024).
- Patrones realistas de demanda: horas pico, fines de semana y estacionalidad.
- Mecanismos de auditoría automática (triggers) y validación de reglas de negocio.
- Vistas, procedimientos almacenados y una función de tarifa dinámica.
- Consultas analíticas complejas listas para ser usadas por un científico de datos.

## Modelo de Datos

<p align="center">
<img src="images/diagrama_er.png" width="900">
</p>

- **Conductores** y **Vehículos** (relación 1:N).
- **Clientes** que solicitan **Viajes**.
- **Calificaciones** asociadas a cada viaje (1:1 con Viajes).
- **Auditoría de tarifas** mediante triggers.

Cada tabla incluye índices diseñados para acelerar las consultas analíticas más frecuentes.

## Estructura del repositorio

| Archivo                  | Contenido |
|--------------------------|-----------|
| `01_DDL.sql`             | Creación de la base de datos, tablas, índices y restricciones. |
| `02_Triggers.sql`        | Triggers de validación de fechas y auditoría de cambios en tarifas. |
| `03_DML.sql`             | Procedimiento `sp_generar_datos_prueba` que inserta 4 meses de datos realistas y activa la auditoría. |
| `04_Vistas.sql`          | Vistas `vista_ingresos_diarios`, `vista_conductores_top`, `vista_demanda_horaria`. |
| `05_Procedimientos.sql`  | Stored Procedures: `sp_reporte_ingresos` y `sp_conductores_mejor_rendimiento`. |
| `06_Funcion.sql`         | Función `fn_calcular_tarifa_dinamica`. |
| `07_Consultas_Analiticas.sql` | 5 consultas avanzadas: ranking horario, riesgo de abandono, segmentación de clientes, detección de anomalías y features para forecasting. |
| `README.md`              | Este archivo. |

## Instalación y uso

1. Clona este repositorio.
2. Ejecuta los scripts en el orden numérico (01 → 02 → 03 …) en tu cliente MySQL.
   - Se recomienda MySQL 5.7 o superior.
3. Al finalizar el script `03_DML.sql` verás el número de registros en la tabla de auditoría.
4. Explora las vistas y procedimientos con las consultas de ejemplo incluidas en cada script.

## Consultas analíticas

El script `07_Consultas_Analiticas.sql` contiene cinco consultas:

### Horas pico – ranking de horas con más viajes.

**Objetivo:** Identificar las horas del día con mayor número de viajes completados, ordenadas de mayor a menor, y asignar un ranking.

**Sirve para:**

- Planificación de flota: saber cuándo se necesita más conductores.
- Estrategia de precios dinámicos: aplicar tarifas más altas en horas de alta demanda.
- Feature para modelos de predicción de demanda.

Las primeras filas corresponden a las horas pico (típicamente 7-9 AM y 5-7 PM). Las últimas muestran las horas valle (madrugada).

<p align="center">
<img src="images/resultado1.png" width="300">
</p>

**Nota:** La imagen no contiene toda la tabla generada. 

### Riesgo de abandono – conductores con caída intermensual >20%.

**Objetivo:**  Detectar conductores que redujeron significativamente su actividad de un mes al siguiente. Un descenso mayor al 20% puede ser señal de insatisfacción, riesgo de abandono o cambio a otra plataforma.

**Sirve para:**

- Retención de talento: recursos humanos puede contactar a estos conductores con incentivos.
- Modelo de predicción de abandono (churn).
- Análisis de estacionalidad o efectos de cambios en políticas.

Esto nos proporciona una lista de conductores, los meses afectados y el porcentaje exacto de caída. Si un conductor aparece varias veces es porque tuvo varios meses malos.

<p align="center">
<img src="images/resultado2.png" width="500">
</p>

### Clientes VIP – cuartil superior de gasto.

**Objetivo:** Clasificar a los clientes según su gasto total y seleccionar el 25% que más consume. Es una segmentación clásica VIP.

**Sirve para:**

- Campañas de fidelización dirigidas a los mejores clientes.
- Análisis RFM (Recency, Frequency, Monetary).
- Definir umbrales para un programa de lealtad.

Esto nos devuelve una tabla con los clientes VIP (cuartil superior) con su gasto total y el número de orden. Se confirma que representan aproximadamente el 25% de la base de clientes que hicieron viajes.

<p align="center">
<img src="images/resultado3.png" width="500">
</p>


4. **Viajes anómalos** – velocidad > media + 2σ (posibles errores de GPS).
5. **Dataset temporal** – series con demanda horaria y valor de la hora anterior.

## 🛠️ Tecnologías

- MySQL 5.7+ (InnoDB)
- Funciones de agregación, subconsultas correlacionadas y variables de sesión.
- Triggers `BEFORE INSERT/UPDATE` para reglas de negocio.

## 📈 Notas para Arquitectos de Datos y Reclutadores

- La elección de índices cubre las consultas más costosas.
- Se utilizó una tabla de auditoría independiente para no sobrecargar la tabla transaccional.
- Los procedimientos devuelven resultados paginados (con `LIMIT`) para integración con dashboards.
- Las consultas analíticas no dependen de extensiones propietarias; pueden adaptarse fácilmente a PostgreSQL o SQL Server.

## 👤 Autor

[Tu nombre] – [Tu perfil de LinkedIn/GitHub]

## 📄 Licencia

MIT – Libre uso, modificación y distribución.
