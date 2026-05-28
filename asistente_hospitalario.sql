-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 28-05-2026 a las 18:03:30
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `asistente_hospitalario`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `acceso_remoto`
--

CREATE TABLE `acceso_remoto` (
  `id_acceso` int(11) NOT NULL,
  `fecha_hora` datetime DEFAULT current_timestamp(),
  `id_personal` int(11) NOT NULL,
  `id_dispositivo` int(11) NOT NULL,
  `accion_realizada` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `acceso_remoto`
--

INSERT INTO `acceso_remoto` (`id_acceso`, `fecha_hora`, `id_personal`, `id_dispositivo`, `accion_realizada`) VALUES
(1, '2026-03-26 09:00:00', 1, 3, 'ABRIR'),
(2, '2026-03-26 09:20:00', 2, 1, 'ENCENDER');

--
-- Disparadores `acceso_remoto`
--
DELIMITER $$
CREATE TRIGGER `trg_after_acceso_remoto` AFTER INSERT ON `acceso_remoto` FOR EACH ROW BEGIN
    DECLARE v_id_comando  INT;
    DECLARE v_id_paciente INT;

    -- Buscar el comando que corresponde a la acción y dispositivo
    SELECT c.id_comando INTO v_id_comando
    FROM   comandos_voz c
    WHERE  c.id_dispositivo = NEW.id_dispositivo
      AND  c.accion         = NEW.accion_realizada
    LIMIT 1;

    -- Buscar el paciente asignado a la habitación del dispositivo
    SELECT p.id_paciente INTO v_id_paciente
    FROM   pacientes p
    JOIN   dispositivos d ON p.id_habitacion = d.id_habitacion
    WHERE  d.id_dispositivo = NEW.id_dispositivo
    LIMIT 1;

    -- Registrar en historial solo si encontró el comando
    IF v_id_comando IS NOT NULL THEN
        INSERT INTO historial_acciones (fecha_hora, id_origen, resultado, id_paciente, id_comando)
        VALUES (NOW(), 2, 'EXITOSO', v_id_paciente, v_id_comando);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comandos_voz`
--

CREATE TABLE `comandos_voz` (
  `id_comando` int(11) NOT NULL,
  `comando_texto` varchar(50) NOT NULL,
  `accion` varchar(50) NOT NULL,
  `id_dispositivo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `comandos_voz`
--

INSERT INTO `comandos_voz` (`id_comando`, `comando_texto`, `accion`, `id_dispositivo`) VALUES
(1, 'LUZ ON', 'ENCENDER', 1),
(2, 'LUZ OFF', 'APAGAR', 1),
(3, 'CAMA ARRIBA', 'SUBIR', 2),
(4, 'CAMA ABAJO', 'BAJAR', 2),
(5, 'PUERTA ABRIR', 'ABRIR', 3),
(6, 'PUERTA CERRAR', 'CERRAR', 3);

--
-- Disparadores `comandos_voz`
--
DELIMITER $$
CREATE TRIGGER `trg_update_comando` AFTER UPDATE ON `comandos_voz` FOR EACH ROW BEGIN
    -- Solo registrar si cambió el texto o la acción
    IF NEW.comando_texto <> OLD.comando_texto OR NEW.accion <> OLD.accion THEN
        INSERT INTO historial_acciones (fecha_hora, id_origen, resultado, id_paciente, id_comando)
        VALUES (NOW(), 2, 'ACTUALIZADO', NULL, NEW.id_comando);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `dispositivos`
--

CREATE TABLE `dispositivos` (
  `id_dispositivo` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `tipo` varchar(30) NOT NULL,
  `id_habitacion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `dispositivos`
--

INSERT INTO `dispositivos` (`id_dispositivo`, `nombre`, `tipo`, `id_habitacion`) VALUES
(1, 'Luz Principal', 'LED', 1),
(2, 'Cama', 'SERVOMOTOR', 1),
(3, 'Puerta', 'SERVOMOTOR', 1),
(4, 'Luz Principal', 'LED', 2),
(5, 'Cama', 'SERVOMOTOR', 2),
(6, 'Puerta', 'SERVOMOTOR', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estados_paciente`
--

CREATE TABLE `estados_paciente` (
  `id_estado` int(11) NOT NULL,
  `id_paciente` int(11) NOT NULL,
  `estado` varchar(30) NOT NULL,
  `fecha_cambio` datetime DEFAULT current_timestamp(),
  `observacion` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `estados_paciente`
--

INSERT INTO `estados_paciente` (`id_estado`, `id_paciente`, `estado`, `fecha_cambio`, `observacion`) VALUES
(1, 1, 'ACTIVO', '2026-04-13 00:19:02', NULL),
(2, 2, 'ACTIVO', '2026-04-13 00:19:02', NULL),
(3, 3, 'ACTIVO', '2026-04-21 08:53:44', 'Estado inicial al ingresar'),
(4, 4, 'ACTIVO', '2026-04-21 08:57:00', 'Estado inicial al ingresar'),
(5, 6, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(6, 7, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(7, 8, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(8, 9, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(9, 10, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(10, 11, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(11, 12, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(12, 13, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(13, 14, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar'),
(14, 15, 'ACTIVO', '2026-04-21 09:04:53', 'Estado inicial al ingresar');

--
-- Disparadores `estados_paciente`
--
DELIMITER $$
CREATE TRIGGER `trg_before_insert_estado` BEFORE INSERT ON `estados_paciente` FOR EACH ROW BEGIN
    DECLARE v_ultimo_estado VARCHAR(30);

    -- Obtener el último estado del paciente
    SELECT estado INTO v_ultimo_estado
    FROM   estados_paciente
    WHERE  id_paciente = NEW.id_paciente
    ORDER BY id_estado DESC
    LIMIT 1;

    -- Si el nuevo estado es igual al último, cancelar
    IF v_ultimo_estado = NEW.estado THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: El paciente ya tiene ese estado registrado';
    END IF;

    -- Asignar fecha si no se envió
    IF NEW.fecha_cambio IS NULL THEN
        SET NEW.fecha_cambio = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `habitaciones`
--

CREATE TABLE `habitaciones` (
  `id_habitacion` int(11) NOT NULL,
  `numero` varchar(10) NOT NULL,
  `piso` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `habitaciones`
--

INSERT INTO `habitaciones` (`id_habitacion`, `numero`, `piso`, `descripcion`) VALUES
(1, '101', 1, 'Habitación individual piso 1'),
(2, '102', 1, 'Habitación individual piso 1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_acciones`
--

CREATE TABLE `historial_acciones` (
  `id_accion` int(11) NOT NULL,
  `fecha_hora` datetime DEFAULT current_timestamp(),
  `resultado` varchar(20) DEFAULT 'EXITOSO',
  `id_paciente` int(11) DEFAULT NULL,
  `id_comando` int(11) DEFAULT NULL,
  `id_origen` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `historial_acciones`
--

INSERT INTO `historial_acciones` (`id_accion`, `fecha_hora`, `resultado`, `id_paciente`, `id_comando`, `id_origen`) VALUES
(1, '2026-03-26 08:00:00', 'EXITOSO', 1, 1, 1),
(2, '2026-03-26 08:30:00', 'EXITOSO', 1, 3, 1),
(3, '2026-03-26 09:00:00', 'EXITOSO', 1, 5, 2),
(4, '2026-03-26 09:15:00', 'EXITOSO', 2, 4, 1);

--
-- Disparadores `historial_acciones`
--
DELIMITER $$
CREATE TRIGGER `trg_before_insert_accion` BEFORE INSERT ON `historial_acciones` FOR EACH ROW BEGIN
    DECLARE v_existe_paciente INT;
    DECLARE v_existe_comando  INT;

    -- Verificar que el paciente existe
    SELECT COUNT(*) INTO v_existe_paciente
    FROM pacientes WHERE id_paciente = NEW.id_paciente;

    -- Verificar que el comando existe
    SELECT COUNT(*) INTO v_existe_comando
    FROM comandos_voz WHERE id_comando = NEW.id_comando;

    -- Si no existen, cancelar la inserción con error
    IF v_existe_paciente = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: El paciente no existe en la base de datos';
    END IF;

    IF v_existe_comando = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: El comando de voz no existe en la base de datos';
    END IF;

    -- Asignar fecha actual si no se envió
    IF NEW.fecha_hora IS NULL THEN
        SET NEW.fecha_hora = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_estados_dispositivo`
--

CREATE TABLE `historial_estados_dispositivo` (
  `id_historial` int(11) NOT NULL,
  `id_dispositivo` int(11) NOT NULL,
  `estado_anterior` varchar(20) DEFAULT NULL,
  `estado_nuevo` varchar(20) NOT NULL,
  `fecha_cambio` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `historial_estados_dispositivo`
--

INSERT INTO `historial_estados_dispositivo` (`id_historial`, `id_dispositivo`, `estado_anterior`, `estado_nuevo`, `fecha_cambio`) VALUES
(1, 1, NULL, 'APAGADO', '2026-04-13 00:19:02'),
(2, 2, NULL, 'ABAJO', '2026-04-13 00:19:02'),
(3, 3, NULL, 'CERRADA', '2026-04-13 00:19:02'),
(4, 4, NULL, 'APAGADO', '2026-04-13 00:19:02'),
(5, 5, NULL, 'ABAJO', '2026-04-13 00:19:02'),
(6, 6, NULL, 'CERRADA', '2026-04-13 00:19:02');

--
-- Disparadores `historial_estados_dispositivo`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_estado_dispositivo` AFTER INSERT ON `historial_estados_dispositivo` FOR EACH ROW BEGIN
    -- Solo registrar si realmente hubo un cambio de estado
    IF NEW.estado_anterior <> NEW.estado_nuevo OR NEW.estado_anterior IS NULL THEN
        INSERT INTO historial_estados_dispositivo (id_dispositivo, estado_anterior, estado_nuevo, fecha_cambio)
        SELECT NEW.id_dispositivo, NEW.estado_anterior, NEW.estado_nuevo, NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM historial_estados_dispositivo
            WHERE id_dispositivo = NEW.id_dispositivo
              AND estado_nuevo   = NEW.estado_nuevo
              AND fecha_cambio   = NEW.fecha_cambio
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_dispositivo` AFTER UPDATE ON `historial_estados_dispositivo` FOR EACH ROW BEGIN
    -- Solo actuar si cambió el estado_nuevo
    IF NEW.estado_nuevo <> OLD.estado_nuevo THEN
        INSERT INTO historial_estados_dispositivo (id_dispositivo, estado_anterior, estado_nuevo, fecha_cambio)
        VALUES (NEW.id_dispositivo, OLD.estado_nuevo, NEW.estado_nuevo, NOW());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pacientes`
--

CREATE TABLE `pacientes` (
  `id_paciente` int(11) NOT NULL,
  `nombre` varchar(80) NOT NULL,
  `apellido` varchar(80) NOT NULL,
  `diagnostico` varchar(200) DEFAULT NULL,
  `fecha_ingreso` date NOT NULL,
  `id_habitacion` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pacientes`
--

INSERT INTO `pacientes` (`id_paciente`, `nombre`, `apellido`, `diagnostico`, `fecha_ingreso`, `id_habitacion`) VALUES
(1, 'Juan', 'Pérez', 'Paraplejía L2', '2026-03-01', 1),
(2, 'María', 'López', 'Paraplejía T4', '2026-03-10', 2),
(3, 'Ignacio', 'Cortez', 'Paraplejía T1', '2026-04-21', 1),
(4, 'Pedro', 'Oblitas', 'Paraplejía T3', '2026-04-21', 1),
(6, 'Juan', 'Nina', 'Paraplejía L2', '2026-01-10', 1),
(7, 'Carla', 'Poma', 'Paraplejía T4', '2026-01-15', 1),
(8, 'Marcelo', 'Tejada', 'Paraplejía C5', '2026-01-20', 1),
(9, 'Juana', 'Titi', 'Esclerosis múltiple', '2026-02-01', 1),
(10, 'Chris', 'Cruz', 'Paraplejía T6', '2026-02-10', 2),
(11, 'María', 'Flores Mamani', 'Lesión medular L1', '2026-02-15', 2),
(12, 'Pedro', 'Huanca Quispe', 'Paraplejía C6', '2026-02-20', 2),
(13, 'Rosa', 'Choque Apaza', 'Lesión medular T3', '2026-03-01', 2),
(14, 'Luis', 'Condori Vargas', 'Paraplejía L4', '2026-03-10', 1),
(15, 'Ana', 'Mamani Tola', 'Esclerosis lateral', '2026-03-15', 2);

--
-- Disparadores `pacientes`
--
DELIMITER $$
CREATE TRIGGER `trg_after_nuevo_paciente` AFTER INSERT ON `pacientes` FOR EACH ROW BEGIN
    INSERT INTO estados_paciente (id_paciente, estado, observacion, fecha_cambio)
    VALUES (NEW.id_paciente, 'ACTIVO', 'Estado inicial al ingresar', NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_delete_paciente` AFTER DELETE ON `pacientes` FOR EACH ROW BEGIN
    -- Eliminar estados del paciente
    DELETE FROM estados_paciente
    WHERE id_paciente = OLD.id_paciente;

    -- Eliminar historial de acciones del paciente
    DELETE FROM historial_acciones
    WHERE id_paciente = OLD.id_paciente;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personal_medico`
--

CREATE TABLE `personal_medico` (
  `id_personal` int(11) NOT NULL,
  `nombre` varchar(80) NOT NULL,
  `apellido` varchar(80) NOT NULL,
  `rol` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `personal_medico`
--

INSERT INTO `personal_medico` (`id_personal`, `nombre`, `apellido`, `rol`) VALUES
(1, 'Carlos', 'Mamani', 'ENFERMERO'),
(2, 'Ana', 'Quispe', 'MEDICO'),
(3, 'Christhofher', 'Molina', 'ADMIN');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipos_origen`
--

CREATE TABLE `tipos_origen` (
  `id_origen` int(11) NOT NULL,
  `nombre` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipos_origen`
--

INSERT INTO `tipos_origen` (`id_origen`, `nombre`) VALUES
(1, 'VOZ'),
(2, 'WEB');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios_acceso`
--

CREATE TABLE `usuarios_acceso` (
  `id_usuario` int(11) NOT NULL,
  `id_personal` int(11) NOT NULL,
  `usuario` varchar(30) NOT NULL,
  `contrasena_hash` varchar(100) NOT NULL,
  `ultimo_acceso` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios_acceso`
--

INSERT INTO `usuarios_acceso` (`id_usuario`, `id_personal`, `usuario`, `contrasena_hash`, `ultimo_acceso`) VALUES
(1, 1, 'cmamani', 'hash_placeholder_1', NULL),
(2, 2, 'aquispe', 'hash_placeholder_2', NULL),
(3, 3, 'cmolina', 'f63b12dbb103224032ac91f2aa557d4e13bced301002c33f9fea418d7826c98e', NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `acceso_remoto`
--
ALTER TABLE `acceso_remoto`
  ADD PRIMARY KEY (`id_acceso`),
  ADD KEY `id_personal` (`id_personal`),
  ADD KEY `id_dispositivo` (`id_dispositivo`);

--
-- Indices de la tabla `comandos_voz`
--
ALTER TABLE `comandos_voz`
  ADD PRIMARY KEY (`id_comando`),
  ADD UNIQUE KEY `comando_texto` (`comando_texto`),
  ADD KEY `id_dispositivo` (`id_dispositivo`);

--
-- Indices de la tabla `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD PRIMARY KEY (`id_dispositivo`),
  ADD KEY `id_habitacion` (`id_habitacion`);

--
-- Indices de la tabla `estados_paciente`
--
ALTER TABLE `estados_paciente`
  ADD PRIMARY KEY (`id_estado`),
  ADD KEY `id_paciente` (`id_paciente`);

--
-- Indices de la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  ADD PRIMARY KEY (`id_habitacion`),
  ADD UNIQUE KEY `numero` (`numero`);

--
-- Indices de la tabla `historial_acciones`
--
ALTER TABLE `historial_acciones`
  ADD PRIMARY KEY (`id_accion`),
  ADD KEY `id_paciente` (`id_paciente`),
  ADD KEY `id_comando` (`id_comando`),
  ADD KEY `id_origen` (`id_origen`);

--
-- Indices de la tabla `historial_estados_dispositivo`
--
ALTER TABLE `historial_estados_dispositivo`
  ADD PRIMARY KEY (`id_historial`),
  ADD KEY `id_dispositivo` (`id_dispositivo`);

--
-- Indices de la tabla `pacientes`
--
ALTER TABLE `pacientes`
  ADD PRIMARY KEY (`id_paciente`),
  ADD KEY `id_habitacion` (`id_habitacion`);

--
-- Indices de la tabla `personal_medico`
--
ALTER TABLE `personal_medico`
  ADD PRIMARY KEY (`id_personal`);

--
-- Indices de la tabla `tipos_origen`
--
ALTER TABLE `tipos_origen`
  ADD PRIMARY KEY (`id_origen`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `usuarios_acceso`
--
ALTER TABLE `usuarios_acceso`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `id_personal` (`id_personal`),
  ADD UNIQUE KEY `usuario` (`usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `acceso_remoto`
--
ALTER TABLE `acceso_remoto`
  MODIFY `id_acceso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `comandos_voz`
--
ALTER TABLE `comandos_voz`
  MODIFY `id_comando` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `dispositivos`
--
ALTER TABLE `dispositivos`
  MODIFY `id_dispositivo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `estados_paciente`
--
ALTER TABLE `estados_paciente`
  MODIFY `id_estado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  MODIFY `id_habitacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `historial_acciones`
--
ALTER TABLE `historial_acciones`
  MODIFY `id_accion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `historial_estados_dispositivo`
--
ALTER TABLE `historial_estados_dispositivo`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `pacientes`
--
ALTER TABLE `pacientes`
  MODIFY `id_paciente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `personal_medico`
--
ALTER TABLE `personal_medico`
  MODIFY `id_personal` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `tipos_origen`
--
ALTER TABLE `tipos_origen`
  MODIFY `id_origen` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `usuarios_acceso`
--
ALTER TABLE `usuarios_acceso`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `acceso_remoto`
--
ALTER TABLE `acceso_remoto`
  ADD CONSTRAINT `acceso_remoto_ibfk_1` FOREIGN KEY (`id_personal`) REFERENCES `personal_medico` (`id_personal`),
  ADD CONSTRAINT `acceso_remoto_ibfk_2` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`);

--
-- Filtros para la tabla `comandos_voz`
--
ALTER TABLE `comandos_voz`
  ADD CONSTRAINT `comandos_voz_ibfk_1` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`);

--
-- Filtros para la tabla `dispositivos`
--
ALTER TABLE `dispositivos`
  ADD CONSTRAINT `dispositivos_ibfk_1` FOREIGN KEY (`id_habitacion`) REFERENCES `habitaciones` (`id_habitacion`);

--
-- Filtros para la tabla `estados_paciente`
--
ALTER TABLE `estados_paciente`
  ADD CONSTRAINT `estados_paciente_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`);

--
-- Filtros para la tabla `historial_acciones`
--
ALTER TABLE `historial_acciones`
  ADD CONSTRAINT `historial_acciones_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`),
  ADD CONSTRAINT `historial_acciones_ibfk_2` FOREIGN KEY (`id_comando`) REFERENCES `comandos_voz` (`id_comando`),
  ADD CONSTRAINT `historial_acciones_ibfk_3` FOREIGN KEY (`id_origen`) REFERENCES `tipos_origen` (`id_origen`);

--
-- Filtros para la tabla `historial_estados_dispositivo`
--
ALTER TABLE `historial_estados_dispositivo`
  ADD CONSTRAINT `historial_estados_dispositivo_ibfk_1` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`);

--
-- Filtros para la tabla `pacientes`
--
ALTER TABLE `pacientes`
  ADD CONSTRAINT `pacientes_ibfk_1` FOREIGN KEY (`id_habitacion`) REFERENCES `habitaciones` (`id_habitacion`);

--
-- Filtros para la tabla `usuarios_acceso`
--
ALTER TABLE `usuarios_acceso`
  ADD CONSTRAINT `usuarios_acceso_ibfk_1` FOREIGN KEY (`id_personal`) REFERENCES `personal_medico` (`id_personal`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
