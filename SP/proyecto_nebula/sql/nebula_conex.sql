--Creamos tablas en el esquema de nebula
show user;
show con_name;

-- PACIENTE 
CREATE TABLE paciente ( paciente_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
                        nombre VARCHAR2(60) NOT NULL, 
                        apellidos VARCHAR2(90) NOT NULL, 
                        nif VARCHAR2(15) UNIQUE, 
                        fecha_nacimiento DATE, 
                        creado_en TIMESTAMP DEFAULT SYSTIMESTAMP 
                       );

-- MEDICO 
CREATE TABLE medico (
                    medico_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
                    nombre VARCHAR2(60) NOT NULL, 
                    especialidad VARCHAR2(60) NOT NULL, 
                    colegiado VARCHAR2(30) UNIQUE, 
                    activo CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')) 
                    );           

-- SERVICIO 
CREATE TABLE servicio ( servicio_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
                        nombre VARCHAR2(80) NOT NULL, 
                        precio_eur NUMBER(8,2) CHECK (precio_eur >= 0), 
                        activo CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')) 
                       );            

-- CITA 
CREATE TABLE cita ( cita_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
                    paciente_id NUMBER NOT NULL REFERENCES paciente(paciente_id), 
                    medico_id NUMBER NOT NULL REFERENCES medico(medico_id), 
                    servicio_id NUMBER NOT NULL REFERENCES servicio(servicio_id), 
                    fecha_hora TIMESTAMP NOT NULL, 
                    estado VARCHAR2(20) DEFAULT 'PROGRAMADA' CHECK (estado IN ('PROGRAMADA','ATENDIDA','CANCELADA')) 
                  );

-- FACTURA y DETALLE 
CREATE TABLE factura ( factura_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
                       paciente_id NUMBER NOT NULL REFERENCES paciente(paciente_id), 
                       fecha_emision DATE DEFAULT SYSDATE, metodo_pago VARCHAR2(20) DEFAULT 'EFECTIVO', 
                       total_eur NUMBER(10,2) DEFAULT 0 CHECK (total_eur >= 0) 
                      );
                    
CREATE TABLE detalle_factura ( detalle_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
                               factura_id NUMBER NOT NULL REFERENCES factura(factura_id), 
                               servicio_id NUMBER NOT NULL REFERENCES servicio(servicio_id), 
                               cantidad NUMBER(6) DEFAULT 1 CHECK (cantidad > 0), 
                               precio_unit NUMBER(8,2) CHECK (precio_unit >= 0) 
                              );

-- Índices útiles 
CREATE INDEX ix_cita_fecha ON cita(fecha_hora); 
CREATE INDEX ix_factura_fecha ON factura(fecha_emision);

--Vista de conveniencia
CREATE OR REPLACE VIEW v_citas_completas AS
SELECT c.cita_id, c.fecha_hora, c.estado, p.paciente_id, p.nombre AS pac_nombre, 
p.apellidos AS pac_apellidos, m.medico_id, m.nombre AS med_nombre, m.especialidad,
s.servicio_id, s.nombre AS serv_nombre, s.precio_eur 
FROM cita c JOIN paciente p ON p.paciente_id = c.paciente_id 
JOIN medico m ON m.medico_id = c.medico_id 
JOIN servicio s ON s.servicio_id = c.servicio_id;

--Tras crear las tablas y sus correspondientes índices podemos comprobar
--si se han creado los segmentos correspondientes a ellas

SELECT * FROM user_segments
WHERE segment_name IN ('PACIENTE','MEDICO','SERVICIO','CITA','FACTURA', 'DETALLE_FACTURA');

--Comprobamos que no se ha creado ningún segmento para las tablas que hemos creado
--lo que significa que el parámetro DEFERRED_SEGMENT_CREATION=TRUE y que hasta que no
--insertemos algún registro no se crearán segmentos para las tablas anteriormente creadas

--Carga de datos
--Tabla Pacientes
INSERT INTO paciente (nombre, apellidos, nif, fecha_nacimiento) 
VALUES ('Lucía', 'Serrano Gómez', '12345678A', DATE '1994-05-11'); 
INSERT INTO paciente (nombre, apellidos, nif, fecha_nacimiento) 
VALUES ('Manuel', 'García López', '98765432B', DATE '1980-10-02');

--Si lo comprobamos ahora, veremos que ya se ha creado un segmento para la tabla paciente
SELECT * FROM user_segments
WHERE segment_name IN ('PACIENTE','MEDICO','SERVICIO','CITA','FACTURA', 'DETALLE_FACTURA');

-- MEDICOS 
INSERT INTO medico (nombre, especialidad, colegiado, activo) 
VALUES ('Dra. Vega', 'Cardiología', 'COL-1001', 'S'); 
INSERT INTO medico (nombre, especialidad, colegiado, activo) 
VALUES ('Dr. Ríos', 'Medicina Interna', 'COL-1002', 'S'); 
INSERT INTO medico (nombre, especialidad, colegiado, activo) 
VALUES ('Dra. Navas', 'Dermatología', 'COL-1003', 'N');
INSERT INTO medico (nombre, especialidad, colegiado, activo) 
VALUES ('Dra. Inventado', 'Psiquiatría', null, 'N');
-- SERVICIOS 
INSERT INTO servicio (nombre, precio_eur, activo) 
VALUES ('Consulta general', 50, 'S'); 
INSERT INTO servicio (nombre, precio_eur, activo) 
VALUES ('Revisión cardiológica', 120, 'S'); 
INSERT INTO servicio (nombre, precio_eur, activo) 
VALUES ('Dermatología básica', 80, 'S');

-- CITAS 
INSERT INTO cita (paciente_id, medico_id, servicio_id, fecha_hora, estado) 
SELECT p.paciente_id, m.medico_id, s.servicio_id, SYSTIMESTAMP + NUMTODSINTERVAL(1,'DAY'), 'PROGRAMADA' 
FROM paciente p, medico m, servicio s WHERE p.nombre = 'Lucía' AND m.nombre = 'Dra. Vega' AND s.nombre = 'Revisión cardiológica';

INSERT INTO cita (paciente_id, medico_id, servicio_id, fecha_hora, estado) 
SELECT p.paciente_id, m.medico_id, s.servicio_id, SYSTIMESTAMP - NUMTODSINTERVAL(3,'DAY'), 'ATENDIDA' 
FROM paciente p, medico m, servicio s WHERE p.nombre = 'Manuel' AND m.nombre = 'Dr. Ríos' AND s.nombre ='Consulta general';

COMMIT;

--Consultas
--1) Citas futuras (>= ahora) con paciente, médico, servicio, fecha (asc):
SELECT p.nombre ||' '|| p.apellidos AS paciente,
m.nombre, s.nombre, c.fecha_hora
FROM Paciente p, Medico m, Servicio s, Cita c
WHERE c.paciente_id = p.paciente_id AND
      c.medico_id = m.medico_id AND
      c.servicio_id = s.servicio_id AND
      fecha_hora >= SYSTIMESTAMP--
ORDER BY c.fecha_hora ASC;
      
--2) Médicos activos por especialidad y nombre:
SELECT m.nombre, m.especialidad
FROM medico m
WHERE activo = 'S'
GROUP BY m.nombre, m.especialidad;

--3) Edad aproximada de cada paciente (en años enteros):
SELECT p.nombre ||' '||p.apellidos, TRUNC(TRUNC(MONTHS_BETWEEN(SYSTIMESTAMP, p.fecha_nacimiento))/12)
FROM paciente p;

--4) Turno de la cita (CASE: mañana/tarde):  HH24:MI:SS
SELECT p.nombre ||' '||p.apellidos AS paciente, TO_CHAR(fecha_hora, 'HH24:MI:SS') AS hora_cita,
       CASE
           WHEN (TO_CHAR(fecha_hora, 'HH24:MI:SS') < '16:00:00') THEN 'MAÑANA'
           ELSE 'TARDE'
       END AS Turno_cita
FROM cita c, paciente p
WHERE c.paciente_id = p.paciente_id;
    
    
--5) NVL/COALESCE y DECODE (ejemplos):
SELECT nombre, NVL(colegiado, 'SIN-COLEGIADO') AS colegiado_ok 
FROM medico; --insertamos un médico cuyo valor de colegiado sea null

SELECT nombre, DECODE(activo, 'S','ACTIVO','N','INACTIVO','?') AS estado_texto 
FROM medico;

--6) Citas atendidas por especialidad y total (ROLLUP):
SELECT m.especialidad, count(*) AS total_citas_atendidas
FROM cita c, medico m
WHERE c.medico_id = m.medico_id AND estado='ATENDIDA'
GROUP BY ROLLUP (m.especialidad);

--7) Recuento por especialidad y por estado en una sola consulta (GROUPING SETS):
SELECT m.especialidad, c.estado, COUNT(*) AS nº_de_citas
FROM medico m, cita c
WHERE c.medico_id = m.medico_id
GROUP BY GROUPING SETS((m.especialidad),(c.estado),());


--8) Crear una factura para 'Manuel' (hoy) con una línea de 'Consulta general':
INSERT INTO factura (paciente_id, fecha_emision, metodo_pago, total_eur)
SELECT p.paciente_id, SYSDATE, 'TARJETA', s.precio_eur
FROM paciente p, servicio s, cita c
WHERE p.nombre='Manuel' AND
s.servicio_id = c.servicio_id AND
c.paciente_id = p.paciente_id; --Insertamos en factura

SELECT * FROM factura;

--Insertamos en detalle factura
INSERT INTO detalle_factura(factura_id, servicio_id, cantidad, precio_unit)
SELECT f.factura_id, s.servicio_id, 1, s.precio_eur
FROM factura f, servicio s, paciente p, cita c
WHERE f.paciente_id = p.paciente_id AND
      p.paciente_id = c.paciente_id AND
      c.servicio_id = s.servicio_id AND
      p.nombre='Manuel';

SELECT * FROM detalle_factura;

--9) JOIN: citas atendidas con precio y nombre completo del paciente:
SELECT p.nombre||' '||p.apellidos AS Paciente, s.precio_eur AS precio
FROM cita c
JOIN paciente p ON p.paciente_id=c.paciente_id
JOIN servicio s ON s.servicio_id=c.servicio_id
WHERE c.estado='ATENDIDA';

--10) Subconsulta correlacionada: pacientes con al menos 1 cita en Cardiología:
SELECT p.nombre||' '||p.apellidos AS paciente
FROM paciente p
WHERE p.paciente_id IN( SELECT c.paciente_id 
                        FROM cita c, medico m
                        WHERE c.medico_id=m.medico_id
                        AND m.especialidad = 'Cardiología');
                        
SELECT p.nombre||' '||p.apellidos AS paciente, m.especialidad
FROM cita c, medico m, paciente p
WHERE c.medico_id=m.medico_id AND
m.especialidad='Cardiología' AND
c.paciente_id=p.paciente_id
GROUP BY paciente, m.especialidad
HAVING count(*)>=1;

--11) Operadores de conjunto (ejemplos): 
-- Pacientes con NIF NO nulo UNION pacientes que tienen citas
SELECT p.nombre ||' '||p.apellidos
FROM paciente p
WHERE p.nif IS NOT NULL
UNION
SELECT p.nombre ||' '||p.apellidos
FROM paciente p, cita c
WHERE p.paciente_id = c.paciente_id;

-- INTERSECT: pacientes con citas y con facturas
SELECT p.nombre ||' '||p.apellidos
FROM paciente p, factura f
WHERE p.paciente_id = f.paciente_id
INTERSECT
SELECT p.nombre ||' '||p.apellidos
FROM paciente p, cita c
WHERE p.paciente_id = c.paciente_id;

--12) MERGE: actualizar precios según una tabla temporal (ejemplo): 
-- Tabla temporal con nuevas tarifas
CREATE GLOBAL TEMPORARY TABLE nuevas_tarifas 
      (
        nombre_id VARCHAR2(50),
        precio_eur NUMBER(8,2)
      )ON COMMIT DELETE ROWS; --los valores de la tabla se eliminaran al finalizar la transacción 
      
--Insertamos valores en la tabla temporal      
INSERT INTO nuevas_tarifas (nombre_id, precio_eur)
VALUES ('Consulta general', 60);
INSERT INTO nuevas_tarifas (nombre_id, precio_eur)
VALUES ('Dermatología básica', 100);
INSERT INTO nuevas_tarifas (nombre_id, precio_eur)
VALUES ('Revisión cardiológica', 90);

SELECT * FROM nuevas_tarifas;

--MERGE
MERGE INTO servicio ts
USING nuevas_tarifas nt
ON(ts.nombre=nt.nombre_id)
WHEN MATCHED THEN
    UPDATE SET ts.precio_eur=nt.precio_eur;
    
--Comprobamos si los valores se han actualizado    
SELECT * FROM servicio;    