--TRABAJO FINAL - PDB_NEBULA
show user;
show con_name;
show pdbs;

--Guardamos el estado de la base de datos para que siempre esté abierta
ALTER PLUGGABLE DATABASE pdb_nebula SAVE STATE;

--Creamos un usuario normal
CREATE USER nebula IDENTIFIED BY nebula 
DEFAULT TABLESPACE users
QUOTA UNLIMITED ON users;

SELECT * FROM dba_users
WHERE username='NEBULA';

--Asignamos privilegios a Nebula
GRANT CONNECT, RESOURCE TO nebula;

--Creación de un perfil de recursos para nebula
CREATE PROFILE perfil_nebula LIMIT
IDLE_TIME 60 --tiempo de inactividad 60 minutos
FAILED_LOGIN_ATTEMPTS 2 --veces que se puede fallar la contraseña
--antes de que se bloquee la cuenta del usuario
PASSWORD_LIFE_TIME 300; --tiempo que durará la contraseña en días

--El valor del siguiente parámetro debe ser true para que se apliquen
--los perfiles de usuario
show parameter RESOURCE_LIMIT;

--Asignamos el perfil de recursos al usuario nebula
ALTER USER nebula PROFILE perfil_nebula;

--Verificamos que se ha asignado el perfil al usuario
SELECT username, profile
FROM dba_users
WHERE username='NEBULA';

--Comprobamos el valor de este parámetro para saber
--en qué momento la base de datos crea los segmentos para
--las tablas
show parameter DEFERRED_SEGMENT_CREATION;


