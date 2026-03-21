--Check container and user
show user; --SYS
show con_name; --CDB$ROOT

--Dynamic views

--Figure out the instance name
SELECT instance_name, host_name, status, edition
FROM v$instance;

--Visualize info about the container database
SELECT name, cdb, con_id, OPEN_MODE
FROM v$database;

--Check the database version
SELECT banner 
FROM v$version;

--Check info about the cdb and pdbs
SELECT con_id, name, open_mode
FROM v$containers;

--Check info about the pdbs
SELECT name, open_mode, con_id
FROM v$pdbs;

--We make sure we created the new pdb
show pdbs;--PDB_EXAMPLE1 has been created

--To make sure the pdb we just created will be 
--open the next time we startup our machine
ALTER PLUGGABLE DATABASE PDB_EXAMPLE1 SAVE STATE;

--CHECK LISTENER STATUS AND SERVICES!!!!

--CREATING A NEW PDB CALLED pdb_example2

--We have to create a directory to put the datafiles
--for the new database. We will create it in the same path
--we have the other databases.
--C:\app\sauky\product\23ai\oradata\FREE\pdb_example2\

--Creating a new pdb
CREATE PLUGGABLE DATABASE pdb_example2 --naming the new pdb
  ADMIN USER admin_pdbex2 IDENTIFIED BY oracle --admin user for this pdb
  ROLES = (dba) -- giving this role to the admin user
  DEFAULT TABLESPACE users --give a default table space
    DATAFILE 'C:\app\sauky\product\23ai\oradata\FREE\pdb_example2\users01.dbf' SIZE 250M AUTOEXTEND ON
  FILE_NAME_CONVERT = ('C:\app\sauky\product\23ai\oradata\FREE\pdbseed\',
                       'C:\app\sauky\product\23ai\oradata\FREE\pdb_example2\');

--Check pdbs
show pdbs;--id 9 -> PDB_EXAMPLE1
          --id 11  -> PDB_EXAMPLE2

--Opening the new pdb
ALTER PLUGGABLE DATABASE pdb_example2 OPEN;

--Save the database state
ALTER PLUGGABLE DATABASE pdb_example2 SAVE STATE;

--Dynamic view to visualize the datafiles and their path
SELECT con_id,file#, name 
FROM V$DATAFILE
WHERE con_id IN (9,11);

--Delete a pdb
ALTER PLUGGABLE DATABASE pdb_example2 CLOSE IMMEDIATE; --close the pdb
DROP PLUGGABLE DATABASE pdb_example2 INCLUDING DATAFILES; --delete the pdb and 
--datafiles

--USER CREATION

--Creating a common user

--Check out the parameter common_user_prefix
show parameter common_user_prefix;--VALUE=C##

--Creating a common user
CREATE USER C##supervisor_user 
IDENTIFIED BY oracle;

--Check if the user was created
SELECT username, account_status, profile, common
FROM DBA_USERS
WHERE username='C##SUPERVISOR_USER';--username must be in capital letters!

--Checking admin_pdbex1 privileges and roles

SELECT * 
FROM USER_ROLE_PRIVS 
WHERE USERNAME='ADMIN_PDBEX1';--GRANTED_ROLE=PDB_DBA

SELECT con_id,grantee,privilege 
FROM cdb_sys_privs 
WHERE grantee='PDB_DBA';

SELECT con_id,grantee,granted_role 
FROM cdb_role_privs 
WHERE grantee='PDB_DBA';

--Giving some privileges to admin_pdbex1

--Move to the container where is the user
ALTER SESSION SET CONTAINER=pdb_example1;
show con_name;

--User creation (local), only exists in the pdb_example1
CREATE USER employee_user1
IDENTIFIED BY oracle;

--Get the DDL statement for the CREATE USER statement
/*We can see that oracle automatically assign by default
the following tablespaces:
  DEFAULT TABLESPACE "USERS"
  TEMPORARY TABLESPACE "TEMP" */
SELECT DBMS_METADATA.GET_DDL('USER','EMPLOYEE_USER1') FROM dual;

--Checking users in the current pdb
SELECT *
FROM ALL_USERS
WHERE USERNAME='EMPLOYEE_USER1';

--Creating another user
CREATE USER employee_user2 
IDENTIFIED BY oracle
default tablespace users 
temporary tablespace temp 
account unlock;

SELECT *
FROM ALL_USERS
ORDER BY username;

--Creating a rol
CREATE ROLE employees_rol;

SELECT * FROM DBA_ROLES
WHERE role='EMPLOYEES_ROL';

--Give privleges to the role
GRANT CREATE SESSION, CREATE TABLE TO employees_rol;

--Check the privileges assign to the role
SELECT * 
FROM ROLE_SYS_PRIVS
WHERE role LIKE 'E%';

--Granting rol to users 
GRANT employees_rol TO employee_user1, employee_user2;

SELECT * 
FROM DBA_ROLE_PRIVS;

--Manage users
--Blocking users
ALTER USER employee_user1 ACCOUNT LOCK;
ALTER USER employee_user2 ACCOUNT LOCK;

SELECT username, account_status, expiry_date
FROM dba_users
WHERE username='EMPLOYEE_USER1' or username='EMPLOYEE_USER2';

ALTER USER employee_user1 ACCOUNT UNLOCK;
ALTER USER employee_user2 ACCOUNT UNLOCK;

--Changing the password
ALTER USER employee_user1 IDENTIFIED BY welcome1;

--Drop a user
DROP USER employee_user2;

--Creating another role
CREATE ROLE full_privileges;

--Creating a table
CREATE TABLE t1 (id number, name VARCHAR2(50));
INSERT INTO t1(id, name)
       VALUES(1, 'Miguel');
INSERT INTO t1(id, name)
       VALUES(2, 'Pepe');
INSERT INTO t1(id, name)
       VALUES(3, 'Rosa');
SELECT * FROM t1;   

--System privileges
GRANT CREATE SESSION, CREATE TABLE, DROP USER, CREATE USER TO full_privileges;

SELECT * 
FROM ROLE_SYS_PRIVS
WHERE role='FULL_PRIVILEGES';

--Object privileges
GRANT SELECT ON t1 TO full_privileges;
GRANT UPDATE(name) ON t1 TO full_privileges;

SELECT *
FROM ROLE_TAB_PRIVS
WHERE role='FULL_PRIVILEGES';

--Grant the role 
GRANT full_privileges TO employee_user1;

--Creating user profile
CREATE PROFILE profile_1 LIMIT
SESSIONS_PER_USER 9
IDLE_TIME 120 --120 minutes
FAILED_LOGIN_ATTEMPTS 3
PASSWORD_LIFE_TIME 300 --300 days
PASSWORD_REUSE_MAX 4;

--Checking RESOURCE_LIMIT value
show parameter resource_limit;--TRUE

--Changing the value for a value user profile
ALTER PROFILE profile_1 LIMIT SESSIONS_PER_USER 13;

--Checking profile user parameters
SELECT resource_name, limit
FROM dba_profiles
WHERE profile='PROFILE_1';

--Creating a new user and assigning a profile user
CREATE USER user_profile IDENTIFIED BY welcome
PROFILE profile_1;

--4.Changing database parameters

--Making sure we are in the cdb
show con_name;

--Visualize how parameters are modifiable
SELECT name,value,isses_modifiable , issys_modifiable , ispdb_modifiable 
FROM V$PARAMETER
ORDER BY name;
--WHERE name='sessions' or name='nls_date_format';

--Parameters can be modifiable in session-level, system-level
--and pdb-level. Let's change some parameters values

--nls_date_format value=null->derived parameter ISSES_MODIFIABLE=TRUE ISPDB_MODIFIABLE=TRUE
ALTER SESSION set nls_date_format= 'dd-month-yyyy';
--The value for this session has changed
SELECT SYSDATE FROM dual;
SELECT name,value,isses_modifiable , issys_modifiable , ispdb_modifiable 
FROM V$PARAMETER
WHERE name='nls_date_format';

--max_idle_time
SELECT *
FROM V$PARAMETER
where name='max_idle_time';

--These changes will be apply in memory and in the spfile
ALTER SYSTEM set max_idle_time=20 scope=both;

--Reset parameter file
ALTER SYSTEM RESET max_idle_time scope=both;
--The value we set up before in the spfile disappeared 

--creating a pfile
/*In the sqlplus:
create pfile='project1.ora' from spfile;
show parameter max_idle_time;
shutdown immediate;
startup pfile=C:\app\sauky\product\23ai\dbhomeFree\database\project1.ora;
show parameter spfile;
show parameter max_idle_time;
*/