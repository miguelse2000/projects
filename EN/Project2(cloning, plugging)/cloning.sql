--1.CLONING PDBS
--check where we are and the user
show con_name;
show user;

--check cdb status
SELECT con_id, name, open_mode
FROM v$database;

--check pdbs status
SELECT con_id, name, open_mode
FROM v$pdbs;

--moving to the pdb we will clone
ALTER SESSION SET CONTAINER=pdb_nebula;
show con_name;

--check users, tables and objetcs in pdb_nebula
SELECT username, DEFAULT_TABLESPACE, common
FROM dba_users
WHERE COMMON='NO';

SELECT *
FROM dba_tables
WHERE owner='NEBULA' OR owner='NEBULA_ADMIN';

SELECT *
FROM dba_objects
WHERE owner='NEBULA' or owner='NEBULA_ADMIN';

--checking datafiles that also will be cloned
SELECT con_id, file#, name
FROM V$DATAFILE;

--Let's clone pdb_nebula to nebula_copy

--Do some uncommited transactions->doesn't allow to clone the pdb, we have to commit all transactions
SELECT * FROM NEBULA.MEDICO;
DESC NEBULA.MEDICO;
INSERT INTO nebula.medico(nombre, especialidad, colegiado, activo)
            VALUES('Dr. Lee', 'Dermatología', null, 'S');
COMMIT;
--To clone the pdb we have to be in the cdb$root
ALTER SESSION SET CONTAINER=cdb$root;
show con_name;

--Create a new pdb
CREATE PLUGGABLE DATABASE nebula_copy FROM pdb_nebula
 FILE_NAME_CONVERT = ('C:\app\sauky\product\23ai\oradata\FREE\pdb_nebula',--pdb path we want to clone
                      'C:\app\sauky\product\23ai\oradata\FREE\nebula_copy'); --path for the new pdb

--checking the new pdb
SELECT con_id, name, open_mode
FROM V$PDBS;
--OPEN_MODE=MOUNTED

--moving to the new pdb
ALTER SESSION SET CONTAINER=nebula_copy;

--changing the open_mode to open
ALTER PLUGGABLE DATABASE OPEN;
show pdbs;-- con_id =10

--check users, tables and objetcs in nebula_copy
SELECT username, DEFAULT_TABLESPACE, common
FROM dba_users
WHERE COMMON='NO';

SELECT *
FROM dba_tables
WHERE owner='NEBULA' OR owner='NEBULA_ADMIN';

SELECT *
FROM dba_objects
WHERE owner='NEBULA' or owner='NEBULA_ADMIN';

--checking datafiles 
SELECT con_id, file#, name
FROM V$DATAFILE;














