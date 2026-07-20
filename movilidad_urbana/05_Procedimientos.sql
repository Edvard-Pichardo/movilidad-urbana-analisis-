-- SCRIPT 05: Procedimientos almacenados para reportes analíticos

USE movilidad_urbana;

DELIMITER $$
-- Reporte de ingresos en un rango de fechas
CREATE PROCEDURE sp_reporte_ingresos(
  IN fecha_inicio DATE,
  IN fecha_fin    DATE
)
BEGIN
  SELECT
    DATE(fecha_hora_inicio) AS dia,
    COUNT(*)                AS viajes_completados,
    SUM(tarifa_final)       AS ingresos,
    ROUND(AVG(tarifa_final),2) AS tarifa_media
  FROM Viajes
  WHERE estado = 'completado'
    AND fecha_hora_inicio >= fecha_inicio
    AND fecha_hora_inicio <  DATE_ADD(fecha_fin, INTERVAL 1 DAY)
  GROUP BY dia
  ORDER BY dia;
END$$

-- Top N conductores con mejor rendimiento (ingresos y rating)
CREATE PROCEDURE sp_conductores_mejor_rendimiento(
  IN fecha_inicio DATE,
  IN fecha_fin    DATE,
  IN top_n        INT
)
BEGIN
  SELECT
    c.id_conductor,
    CONCAT(c.nombre, ' ', c.apellido) AS nombre,
    COUNT(v.id_viaje)                  AS viajes_realizados,
    SUM(v.tarifa_final)                AS ingresos,
    ROUND(COALESCE(AVG(cal.puntuacion),0),2) AS rating_promedio
  FROM Conductores c
  JOIN Vehiculos ve ON c.id_conductor = ve.id_conductor
  JOIN Viajes v ON v.id_vehiculo = ve.id_vehiculo
               AND v.estado = 'completado'
               AND v.fecha_hora_inicio >= fecha_inicio
               AND v.fecha_hora_inicio <  DATE_ADD(fecha_fin, INTERVAL 1 DAY)
  LEFT JOIN Calificaciones cal ON cal.id_viaje = v.id_viaje
  GROUP BY c.id_conductor
  ORDER BY ingresos DESC
  LIMIT top_n;
END$$
DELIMITER ;