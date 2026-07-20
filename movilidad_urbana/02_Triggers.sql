-- SCRIPT 02: Triggers de integridad y auditoría
-- En este script se implementan las reglas de negocio que no pueden ser
-- expresadas únicamente con restricciones CHECK
-- y el mecanismo de auditoría automática de cambios de tarifas.

USE movilidad_urbana;

-- Validación de coherencia entre fechas de inicio y fin del viaje
-- Un viaje no puede terminar antes (o al mismo tiempo) de haber comenzado.

DELIMITER $$
CREATE TRIGGER tr_viaje_validar_fechas
BEFORE INSERT ON Viajes
FOR EACH ROW
BEGIN
  -- Si la fecha de fin no es nula y no es posterior a la de inicio, cancelamos.
  IF NEW.fecha_hora_fin IS NOT NULL AND NEW.fecha_hora_fin <= NEW.fecha_hora_inicio THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: La fecha de fin debe ser posterior a la fecha de inicio del viaje.';
  END IF;
END$$

-- Repetimos la misma lógica para el evento UPDATE
CREATE TRIGGER tr_viaje_validar_fechas_update
BEFORE UPDATE ON Viajes
FOR EACH ROW
BEGIN
  IF NEW.fecha_hora_fin IS NOT NULL AND NEW.fecha_hora_fin <= NEW.fecha_hora_inicio THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: La fecha de fin debe ser posterior a la fecha de inicio del viaje.';
  END IF;
END$$
DELIMITER ;

-- Auditoría de cambios en tarifas
-- Cada vez que se actualiza una tarifa (base o final) en la tabla Viajes,
-- se registra el valor anterior y el nuevo en Auditoria_Tarifas.

DELIMITER $$
CREATE TRIGGER tr_auditar_cambio_tarifa
AFTER UPDATE ON Viajes
FOR EACH ROW
BEGIN
  -- Solo auditamos si hubo un cambio real en alguna de las tarifas
  IF (NEW.tarifa_base IS NOT NULL AND OLD.tarifa_base IS NOT NULL AND NEW.tarifa_base != OLD.tarifa_base)
     OR (NEW.tarifa_final IS NOT NULL AND OLD.tarifa_final IS NOT NULL AND NEW.tarifa_final != OLD.tarifa_final) THEN

    INSERT INTO Auditoria_Tarifas (
      id_viaje,
      tarifa_base_anterior, tarifa_base_nueva,
      tarifa_final_anterior, tarifa_final_nueva,
      usuario
    ) VALUES (
      NEW.id_viaje,
      OLD.tarifa_base, NEW.tarifa_base,
      OLD.tarifa_final, NEW.tarifa_final,
      CURRENT_USER()
    );
  END IF;
END$$
DELIMITER ;