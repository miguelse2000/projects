--2.Unplugging and plugging
show con_name;--NEBULA_COPY

--check nebula_copy open mode
show pdbs;--READ WRITE

--We have to be in the root container to unplug the pdb
ALTER SESSION SET CONTAINER=cdb$root;
show con_name;

--Step 1: close the database we want to unplug
ALTER PLUGGABLE DATABASE nebula_copy CLOSE IMMEDIATE;

SELECT con_id, name, open_mode
FROM v$pdbs
WHERE name='NEBULA_COPY';

--Step2: unplug the pdb nebula_copy
ALTER PLUGGABLE DATABASE nebula_copy 
UNPLUG INTO 'C:\app\sauky\product\23ai\oradata\nebula.xml';

--pdb nebula_copy still exists

--Step3:deleting nebula_copy but keeping the datafiles
DROP PLUGGABLE DATABASE nebula_copy KEEP DATAFILES;

--We won't see the pdb
SELECT con_id, name, open_mode
FROM v$pdbs
WHERE name='NEBULA_COPY';

--Step 4: plugging the database 
CREATE PLUGGABLE DATABASE nebula_copy2
USING 'C:\app\sauky\product\23ai\oradata\nebula.xml'
FILE_NAME_CONVERT=('C:\app\sauky\product\23ai\oradata\FREE\nebula_copy',--path where the nebula_copy datafiles are located
                   'C:\app\sauky\product\23ai\oradata\FREE\nebula_copy2');--path where the nebula_copy2 datafiles will be placed

--Checking the pdbs                    
SELECT con_id, name, open_mode
FROM v$pdbs;

--Opening the new pdb nebula_copy2
ALTER PLUGGABLE DATABASE nebula_copy2 OPEN;

--Doing some queries to check if the info exists
ALTER SESSION SET CONTAINER=nebula_copy2;
SELECT * FROM NEBULA.MEDICO;

--Checking datafiles
SELECT con_id, file#, name
FROM V$DATAFILE;



