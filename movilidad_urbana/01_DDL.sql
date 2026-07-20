-- PROYECTO: Sistema de Análisis de Movilidad Urbana y Transporte
-- SCRIPT 01: Creación de la base de datos y tablas (DDL)
-- Este script crea la estructura relacional que soporta una plataforma de movilidad tipo Uber/DiDi.

CREATE DATABASE IF NOT EXISTS movilidad_urbana
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE movilidad_urbana;

-- Tabla de Conductores
CREATE TABLE Conductores (
  id_conductor   INT AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(50)  NOT NULL,
  apellido       VARCHAR(50)  NOT NULL,
  -- Email válido básico (contiene @ y .)
  email          VARCHAR(100) NOT NULL CHECK (email LIKE '%_@__%.__%'),
  telefono       VARCHAR(20)  NOT NULL,
  fecha_contratacion DATE     NOT NULL,
  licencia       VARCHAR(30)  NOT NULL,
  estado         ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  -- Búsqueda rápida por email para login
  UNIQUE INDEX idx_email (email),
  -- Filtrado por estado activo/inactivo
  INDEX idx_estado (estado)
) ENGINE=InnoDB;

-- Tabla de Vehículos
CREATE TABLE Vehiculos (
  id_vehiculo  INT AUTO_INCREMENT PRIMARY KEY,
  placa        VARCHAR(10) NOT NULL UNIQUE,
  marca        VARCHAR(30) NOT NULL,
  modelo       VARCHAR(30) NOT NULL,
  anio         YEAR        NOT NULL,
  tipo         ENUM('sedan','suv','hatchback','moto','van') NOT NULL,
  id_conductor INT         NOT NULL,
  -- Un vehículo pertenece a un conductor. 
  -- Si se intenta eliminar un conductor con vehículos asignados, la acción se restringe.
  CONSTRAINT fk_vehiculo_conductor FOREIGN KEY (id_conductor)
    REFERENCES Conductores(id_conductor)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  -- Obtener todos los vehículos de un conductor rápidamente
  INDEX idx_vehiculo_conductor (id_conductor),
  -- Reportes por tipo de vehículo
  INDEX idx_tipo (tipo)
) ENGINE=InnoDB;

-- Tabla de Clientes
CREATE TABLE Clientes (
  id_cliente   INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(50) NOT NULL,
  apellido     VARCHAR(50) NOT NULL,
  -- Email válido
  email        VARCHAR(100) NOT NULL CHECK (email LIKE '%_@__%.__%'),
  telefono     VARCHAR(20)  NOT NULL,
  fecha_registro DATE       NOT NULL,
  -- Evitar duplicados de email
  UNIQUE INDEX idx_cliente_email (email)
) ENGINE=InnoDB;

-- Tabla de Viajes
CREATE TABLE Viajes (
  id_viaje        INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente      INT          NOT NULL,
  id_vehiculo     INT          NOT NULL,
  fecha_hora_inicio DATETIME   NOT NULL,
  fecha_hora_fin    DATETIME   DEFAULT NULL,
  origen_lat      DECIMAL(10,7) NOT NULL,
  origen_lon      DECIMAL(10,7) NOT NULL,
  destino_lat     DECIMAL(10,7) NOT NULL,
  destino_lon     DECIMAL(10,7) NOT NULL,
  distancia_km    DECIMAL(8,2) DEFAULT 0 COMMENT 'Distancia calculada por GPS',
  tarifa_base     DECIMAL(8,2) NOT NULL,
  tarifa_final    DECIMAL(8,2) DEFAULT NULL COMMENT 'Se calcula al finalizar el viaje',
  estado          ENUM('completado','cancelado','en_curso') NOT NULL DEFAULT 'en_curso',
  -- Llave foránea hacia el cliente que solicitó el viaje
  CONSTRAINT fk_viaje_cliente FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente) ON DELETE RESTRICT ON UPDATE CASCADE,
  -- Llave foránea hacia el vehículo utilizado
  CONSTRAINT fk_viaje_vehiculo FOREIGN KEY (id_vehiculo)
    REFERENCES Vehiculos(id_vehiculo) ON DELETE RESTRICT ON UPDATE CASCADE,
  -- Índices para consultas analíticas frecuentes
  INDEX idx_viaje_fecha_inicio (fecha_hora_inicio),              -- reportes por rango de fechas
  INDEX idx_viaje_vehiculo_fecha (id_vehiculo, fecha_hora_inicio), -- rendimiento por conductor/vehículo
  INDEX idx_viaje_cliente (id_cliente),                          -- historial de un cliente
  INDEX idx_estado (estado)                                      -- filtrar viajes completados/cancelados
) ENGINE=InnoDB;

-- Tabla de Calificaciones
CREATE TABLE Calificaciones (
  id_calificacion INT AUTO_INCREMENT PRIMARY KEY,
  id_viaje        INT NOT NULL,
  id_cliente      INT NOT NULL,
  id_conductor    INT NOT NULL, -- redundancia controlada para acelerar agregaciones
  puntuacion      TINYINT NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
  comentario      TEXT,
  fecha_calificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Un viaje solo puede tener una calificación
  CONSTRAINT uq_calificacion_viaje UNIQUE (id_viaje),
  -- Al eliminar un viaje se elimina su calificación
  CONSTRAINT fk_calificacion_viaje FOREIGN KEY (id_viaje)
    REFERENCES Viajes(id_viaje) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_calificacion_cliente FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_calificacion_conductor FOREIGN KEY (id_conductor)
    REFERENCES Conductores(id_conductor) ON DELETE RESTRICT ON UPDATE CASCADE,
  -- Índice para rating promedio por conductor
  INDEX idx_calificacion_conductor (id_conductor, fecha_calificacion)
) ENGINE=InnoDB;

-- Tabla de Auditoría de Tarifas
CREATE TABLE Auditoria_Tarifas (
  id_auditoria       INT AUTO_INCREMENT PRIMARY KEY,
  id_viaje           INT NOT NULL,
  tarifa_base_anterior  DECIMAL(8,2),
  tarifa_base_nueva     DECIMAL(8,2),
  tarifa_final_anterior DECIMAL(8,2),
  tarifa_final_nueva    DECIMAL(8,2),
  fecha_cambio       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  usuario            VARCHAR(50) DEFAULT 'SISTEMA',
  -- Índice para consultar cambios de un viaje específico
  INDEX idx_auditoria_viaje (id_viaje)
) ENGINE=InnoDB;