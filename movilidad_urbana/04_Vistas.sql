-- SCRIPT 04: Vistas para reportes ejecutivos
-- Estas vistas encapsulan consultas frecuentes que muestran la evolución del
-- negocio, el rendimiento de los conductores y los patrones de demanda.

USE movilidad_urbana;

-- Vista 1: Ingresos diarios
CREATE OR REPLACE VIEW vista_ingresos_diarios AS
SELECT
  DATE(fecha_hora_inicio) AS dia,          -- fecha sin hora
  COUNT(*)                 AS total_viajes,
  SUM(tarifa_final)        AS ingresos_totales,
  AVG(tarifa_final)        AS tarifa_promedio,
  SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) AS viajes_cancelados
FROM Viajes
WHERE estado IN ('completado','cancelado') -- consideramos ambos para el total
GROUP BY dia
ORDER BY dia;

-- Vista 2: Top conductores (ingresos, viajes y rating)
CREATE OR REPLACE VIEW vista_conductores_top AS
SELECT
  c.id_conductor,
  CONCAT(c.nombre, ' ', c.apellido) AS nombre_completo,
  COUNT(v.id_viaje)                  AS viajes_completados,
  SUM(v.tarifa_final)                AS ingresos_generados,
  ROUND(AVG(cal.puntuacion), 2)      AS rating_promedio
FROM Conductores c
JOIN Vehiculos ve ON c.id_conductor = ve.id_conductor
JOIN Viajes v ON v.id_vehiculo = ve.id_vehiculo AND v.estado = 'completado'
LEFT JOIN Calificaciones cal ON cal.id_viaje = v.id_viaje
WHERE c.estado = 'activo'         -- solo conductores activos
GROUP BY c.id_conductor
ORDER BY ingresos_generados DESC;

-- Vista 3: Demanda horaria promedio
CREATE OR REPLACE VIEW vista_demanda_horaria AS
SELECT
  HOUR(fecha_hora_inicio) AS hora_del_dia,
  COUNT(*)                AS total_viajes,
  AVG(tarifa_final)       AS tarifa_promedio
FROM Viajes
WHERE estado = 'completado'
GROUP BY hora_del_dia
ORDER BY hora_del_dia;