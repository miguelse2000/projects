--PROJECT 3-BACKUP

--Checking the archive log state
ARCHIVE LOG LIST;

--Enabling the archive log mode
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
alter database archivelog;
ALTER DATABASE OPEN;
ALTER PLUGGABLE DATABASE ALL OPEN;

--recovery fast area parameters
show parameter db_recovery_file_dest;
show parameter db_recovery_file_dest_size;

--We could change these parameters values
--ALTER SYSTEM SET db_recovery_file_dest_size=;
--ALTER SYSTEM SET db_recovery_file_dest=;

--We're going to delete some pdbs 
show pdbs;
DROP PLUGGABLE DATABASE pdbx1 INCLUDING DATAFILES;
DROP PLUGGABLE DATABASE pdbx2 INCLUDING DATAFILES;
ALTER PLUGGABLE DATABASE pdb_example1 CLOSE;
DROP PLUGGABLE DATABASE pdb_example1 INCLUDING DATAFILES;
ALTER PLUGGABLE DATABASE nebula_copy2 CLOSE;
DROP PLUGGABLE DATABASE nebula_copy2 INCLUDING DATAFILES;

show parameter log_archive_dest;
show parameter spfile;

--2.UNDERSTANDING RMAN ENVIRONMENT
--In the terminal/cmd:
/*
--login to rman
rman target=/
--see backups
list backup of database;
--list the archived logs
list archivelog all;
--create backup and generate archivelogs (also control files, spfile)
backup database plus archivelog;
--list controlfiles
list backup of controlfile;
--list spfile backups
list backup of spfile
--deleting old archivelog
delete archivelog until time ‘SYSDATE-10’;
*/

--3.BACKING UP THE FULL CDB
--Before carry out the backup we will execute some transactions
show pdbs;
ALTER SESSION SET CONTAINER=pdb_nebula;
CREATE TABLE NEBULA.CENTROS_MEDICOS( nombre VARCHAR2(50),
                                     ciudad VARCHAR2(50));
DESC NEBULA.CENTROS_MEDICOS;
INSERT INTO NEBULA.CENTROS_MEDICOS(nombre, ciudad)
                            VALUES('Joaquín Sorolla', 'Valencia');
INSERT INTO NEBULA.CENTROS_MEDICOS(nombre, ciudad)
                            VALUES('Hospital de la Princesa', 'Madrid');   
                            
SELECT * FROM NEBULA.CENTROS_MEDICOS;

COMMIT;

--The backup we created won't contain this table we just created, however
--the archive redo log contains it

--Restoring the backup for the CDB (in the RMAN)
/*
RUN
{
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RESTORE DATABASE;--put the database files again in the original location
RECOVER DATABASE;--recover the archive redo log
ALTER DATABASE OPEN;
}
*/

--We will be able to see the table and the 2 rows
SELECT * FROM NEBULA.CENTROS_MEDICOS;

--4.BACKING UP A PDB
show pdbs;

--In the terminal:
/*
--restore the pdb_nebula
RUN 
{
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RESTORE PLUGGABLE DATABASE pdb_nebula;
RECOVER PLUGGABLE DATABASE pdb_nebula;
ALTER PLUGGABLE DATABASE pdb_nebula OPEN;-->ALTER DATABASE OPEN;
}
*/

show pdbs;--all of them are in MOUNTED open mode
ALTER DATABASE OPEN;
ALTER PLUGGABLE DATABASE pdb_nebula OPEN;

--5.POINT-IN-TIME RECOVERY
ALTER SESSION SET CONTAINER=pdb_nebula;
show con_name;
SELECT * FROM NEBULA.CENTROS_MEDICOS;

--Get the timepstamp por the PITR
SELECT TO_CHAR(sysdate, 'DD-MM-YYYY HH24:MI:SS') 
FROM DUAL;
--31-03-2026 19:14:36

--I delete the table
DROP TABLE NEBULA.CENTROS_MEDICOS;
COMMIT;

--In the RMAN:
/*
RUN
{
ALTER PLUGGABLE DATABASE pdb_nebula CLOSE;
SET UNTIL TIME "TO_DATE('31-03-2026 19:14:36','DD-MM-YYYY HH24:MI:SS')";
RESTORE PLUGGABLE DATABASE pdb_nebula;
RECOVER PLUGGABLE DATABASE pdb_nebula;
ALTER PLUGGABLE DATABASE pdb_nebula OPEN RESETLOGS;
}

*/

--Let's check if we have the table CENTROS_MEDICOS;
SELECT * FROM NEBULA.CENTROS_MEDICOS;
