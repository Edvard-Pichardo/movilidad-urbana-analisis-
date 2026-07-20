-- SCRIPT 03: Generación de datos de prueba y activación de la auditoría
-- Este script crea un procedimiento almacenado que inserta 4 meses de datos
-- simulando patrones reales de demanda (horas pico, fines de semana) y,
-- posteriormente, ejecuta una actualización masiva para generar registros
-- en la tabla de auditoría de tarifas.

USE movilidad_urbana;

DELIMITER $$
CREATE PROCEDURE sp_generar_datos_prueba()
BEGIN
  -- Variables de control
  DECLARE v_fecha DATE DEFAULT '2026-06-01';
  DECLARE v_fecha_fin DATE DEFAULT '2026-09-30';
  DECLARE v_dia_semana INT;  -- 1=domingo, 7=sábado
  DECLARE v_hora INT;
  DECLARE v_base_trips INT;          -- viajes esperados en el día
  DECLARE v_lambda DECIMAL(5,2);     -- promedio de viajes en la franja horaria
  DECLARE v_num_trips INT;
  DECLARE i INT;
  DECLARE v_id_cliente INT;
  DECLARE v_id_vehiculo INT;
  DECLARE v_inicio DATETIME;
  DECLARE v_fin DATETIME;
  DECLARE v_distancia DECIMAL(8,2);
  DECLARE v_tarifa_base DECIMAL(8,2);
  DECLARE v_tarifa_final DECIMAL(8,2);
  DECLARE v_duracion INT;  -- duración del viaje en minutos
  DECLARE v_estado ENUM('completado','cancelado','en_curso');

  -- Desactivar temporalmente las restricciones de llave foránea para acelerar la carga
  SET FOREIGN_KEY_CHECKS = 0;

  -- Insertamos 10 conductores
  INSERT INTO Conductores (nombre, apellido, email, telefono, fecha_contratacion, licencia, estado) VALUES
  ('Javier','Lopez','javier.lopez@email.com','555-1001','2025-05-15','LIC-001','activo'),
  ('Fernanda','García','fernanda.garcia@email.com','555-1002','2025-06-20','LIC-002','activo'),
  ('Oscar','Martínez','oscar.martinez@email.com','555-1003','2025-01-10','LIC-003','activo'),
  ('Anita','Ramírez','anita.ramirez@email.com','555-1004','2025-11-05','LIC-004','inactivo'),
  ('Jeremías','Fernández','jeremias.fernandez@email.com','555-1005','2025-03-22','LIC-005','activo'),
  ('Sofía','Torres','sofia.torres@email.com','555-1006','2025-09-14','LIC-006','activo'),
  ('Carlos','Morales','carlos.morales@email.com','555-1007','2025-07-01','LIC-007','activo'),
  ('Rosa','Castro','rosa.castro@email.com','555-1008','2025-12-11','LIC-008','activo'),
  ('Javi','Fernández','javier.fernandez@email.com','555-1009','2025-02-18','LIC-009','activo'),
  ('Carmen','Ozuna','carmen.ozuna@email.com','555-1010','2025-04-30','LIC-010','activo');

  -- Insertamos algunos vehículos (algunos conductores pueden tener más de uno)
  INSERT INTO Vehiculos (placa, marca, modelo, anio, tipo, id_conductor) VALUES
  ('ABC123','Toyota','Corolla',2022,'sedan',1),
  ('DEF456','Honda','Civic',2021,'sedan',2),
  ('GHI789','Nissan','Versa',2023,'sedan',3),
  ('JKL012','Chevrolet','Tracker',2022,'suv',5),
  ('MNO345','Ford','Escape',2021,'suv',6),
  ('PQR678','Hyundai','Tucson',2023,'suv',7),
  ('STU901','Kia','Rio',2020,'hatchback',8),
  ('VWX234','Renault','Duster',2022,'suv',9),
  ('YZA567','Mazda','CX-5',2023,'suv',10),
  ('BCD890','Toyota','Yaris',2021,'hatchback',1),
  ('EFG123','Honda','HR-V',2022,'suv',2),
  ('HIJ456','Nissan','Kicks',2023,'suv',5);

  -- Insertamos 50 clientes con fechas de registro aleatorias en enero-marzo 2026
  INSERT INTO Clientes (nombre, apellido, email, telefono, fecha_registro)
  SELECT CONCAT('Cliente',n), 'Apellido', CONCAT('cliente',n,'@email.com'), CONCAT('555-9',LPAD(n,3,'0')), '2026-01-01' + INTERVAL FLOOR(RAND()*90) DAY
  FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
    UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
    UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50
  ) nums;

  -- Generamos viajes día por día y hora por hora dentro del periodo definido
  WHILE v_fecha <= v_fecha_fin DO
    SET v_dia_semana = DAYOFWEEK(v_fecha);
    -- Los días entre semana tienen más viajes que los fines de semana
    IF v_dia_semana BETWEEN 2 AND 6 THEN
      SET v_base_trips = 150 + FLOOR(RAND()*100);   -- entre 150 y 200
    ELSE
      SET v_base_trips = 80 + FLOOR(RAND()*50);    -- entre 80 y 120
    END IF;

    SET v_hora = 0;
    WHILE v_hora < 24 DO
      -- Distribución de la demanda a lo largo del día
      CASE
        WHEN v_hora BETWEEN 7 AND 9 OR v_hora BETWEEN 17 AND 19 THEN
          SET v_lambda = v_base_trips * 0.14;   -- hora pico (14% del total diario)
        WHEN v_hora BETWEEN 10 AND 16 OR v_hora BETWEEN 20 AND 22 THEN
          SET v_lambda = v_base_trips * 0.05;   -- hora normal
        ELSE
          SET v_lambda = v_base_trips * 0.015;  -- hora valle / madrugada
      END CASE;

      -- Número de viajes en esta franja, con un máximo de 15
      SET v_num_trips = FLOOR(v_lambda + RAND()*2);
      IF v_num_trips > 15 THEN SET v_num_trips = 15; END IF;

      SET i = 1;
      WHILE i <= v_num_trips DO
        -- Seleccionar cliente y vehículo al azar
        SET v_id_cliente = 1 + FLOOR(RAND()*50);
        SET v_id_vehiculo = 1 + FLOOR(RAND()*12);

        -- Hora de inicio aleatoria dentro de la franja horaria
        SET v_inicio = CONCAT(v_fecha, ' ', LPAD(v_hora,2,'0'), ':', LPAD(FLOOR(RAND()*60),2,'0'), ':', LPAD(FLOOR(RAND()*60),2,'0'));

        -- Duración aleatoria entre 5 y 60 minutos
        SET v_duracion = 5 + FLOOR(RAND()*55);
        SET v_fin = DATE_ADD(v_inicio, INTERVAL v_duracion MINUTE);

        -- Distancia estimada (km) basada en velocidad promedio de 25-50 km/h
        SET v_distancia = ROUND((v_duracion/60) * (25 + RAND()*25), 2);

        -- Cálculo de tarifas
        SET v_tarifa_base = 5.00;
        SET v_tarifa_final = ROUND(5.00 + (v_distancia * 1.5) + (v_duracion * 0.2), 2);

        -- Estado del viaje: 90% completado, 8% cancelado, 2% en curso
        SET v_estado = CASE
          WHEN RAND() < 0.90 THEN 'completado'
          WHEN RAND() < 0.98 THEN 'cancelado'
          ELSE 'en_curso'
        END;

        INSERT INTO Viajes (id_cliente, id_vehiculo, fecha_hora_inicio, fecha_hora_fin,
                            origen_lat, origen_lon, destino_lat, destino_lon,
                            distancia_km, tarifa_base, tarifa_final, estado)
        VALUES (
          v_id_cliente, v_id_vehiculo, v_inicio,
          IF(v_estado='completado', v_fin, NULL),
          19.4326 + RAND()*0.1, -99.1332 + RAND()*0.1,  -- coordenadas aleatorias en CDMX
          19.4000 + RAND()*0.1, -99.1000 + RAND()*0.1,
          v_distancia, v_tarifa_base,
          IF(v_estado='completado', v_tarifa_final, NULL),
          v_estado
        );
        SET i = i + 1;
      END WHILE;
      SET v_hora = v_hora + 1;
    END WHILE;
    SET v_fecha = DATE_ADD(v_fecha, INTERVAL 1 DAY);
  END WHILE;

  -- Generamos calificaciones para aproximadamente el 85% de los viajes completados
  INSERT INTO Calificaciones (id_viaje, id_cliente, id_conductor, puntuacion, comentario, fecha_calificacion)
  SELECT
    v.id_viaje,
    v.id_cliente,
    ve.id_conductor,
    FLOOR(3 + RAND()*3),   -- puntuación entre 3 y 5
    CASE FLOOR(RAND()*5)
      WHEN 0 THEN 'Buen viaje'
      WHEN 1 THEN 'Conducción suave'
      WHEN 2 THEN 'Llegó rápido'
      WHEN 3 THEN 'Auto limpio'
      ELSE 'Muy amable'
    END,
    DATE_ADD(v.fecha_hora_fin, INTERVAL FLOOR(RAND()*60) MINUTE)
  FROM Viajes v
  JOIN Vehiculos ve ON v.id_vehiculo = ve.id_vehiculo
  WHERE v.estado = 'completado'
    AND RAND() < 0.85;

  -- Reactivar las llaves foráneas
  SET FOREIGN_KEY_CHECKS = 1;
END$$
DELIMITER ;

-- Ejecutar la generación de datos
CALL sp_generar_datos_prueba(); -- Tarda un poco en generarse

-- Activación de la auditoría de tarifas
-- Para que la tabla Auditoria_Tarifas no quede vacía, simulamos un ajuste
-- masivo de tarifa final (incremento del 10%) en aproximadamente el 5% de los
-- viajes completados. Esto disparará el trigger tr_auditar_cambio_tarifa.
UPDATE Viajes
SET tarifa_final = tarifa_final * 1.10
WHERE estado = 'completado'
  AND id_viaje MOD 20 = 0;   -- aplica a 1 de cada 20 viajes completados

-- Verificación: cuántos registros de auditoría se generaron
SELECT COUNT(*) AS total_auditorias FROM Auditoria_Tarifas;