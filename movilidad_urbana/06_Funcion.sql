-- SCRIPT 06: Función de tarifa dinámica

USE movilidad_urbana;

DELIMITER $$
-- Calcula la tarifa final aplicando un factor de demanda.
-- Ejemplo: factor 1.0 = normal, 1.5 = alta demanda (hora pico), 0.8 = baja demanda.
CREATE FUNCTION fn_calcular_tarifa_dinamica(
  distancia_km    DECIMAL(10,2),   -- distancia en kilómetros
  duracion_min    INT,             -- duración en minutos
  factor_demanda  DECIMAL(3,2)     -- factor multiplicador (1.00 base)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC       -- mismo resultado para mismos argumentos
READS SQL DATA      -- solo lectura de datos, no modifica
BEGIN
  DECLARE tarifa_base DECIMAL(10,2);
  -- Tarifa base = costo fijo + costo por km + costo por minuto
  SET tarifa_base = 5.00 + (distancia_km * 1.50) + (duracion_min * 0.20);
  -- Aplicar el factor de demanda y redondear a dos decimales
  RETURN ROUND(tarifa_base * factor_demanda, 2);
END$$
DELIMITER ;