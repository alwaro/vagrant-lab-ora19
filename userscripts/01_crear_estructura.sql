-- #########################################################################################################
-- #########################################################################################################
--   CREANDO ESTRUCTURA BASICA DE DATOS PARA PRUEBAS CON VARIOS ESQUEMAS Y ALGUNAS TABLAS EN VARIOS TS
-- #########################################################################################################
-- #########################################################################################################

-- CONFIGURAMOS PARAMETRO 
alter system set db_create_file_dest='/opt/oracle/oradata' scope=both;

-- CAMBIAMOS A LA PDB
ALTER SESSION SET CONTAINER=ORCLPDB1;

-- CONFIGURAMOS PARAMETRO 
alter system set db_create_file_dest='/opt/oracle/oradata' scope=both;

-- CREAMOS TABLESPACES
CREATE BIGFILE TABLESPACE USER1TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;
CREATE BIGFILE TABLESPACE USER2TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;
CREATE BIGFILE TABLESPACE USER3TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;
CREATE BIGFILE TABLESPACE USER4TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;
CREATE BIGFILE TABLESPACE COMUNTS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;

-- CREAMOS USUAROS
CREATE USER USER1 IDENTIFIED BY USER1 DEFAULT TABLESPACE USER1TS;
CREATE USER USER2 IDENTIFIED BY USER2 DEFAULT TABLESPACE USER2TS;
CREATE USER USER3 IDENTIFIED BY USER3 DEFAULT TABLESPACE USER3TS;
CREATE USER USER4 IDENTIFIED BY USER4 DEFAULT TABLESPACE USER4TS;
CREATE USER AJENO1 IDENTIFIED BY AJENO1 DEFAULT TABLESPACE COMUNTS;

-- DAMOS QUOTAS Y PERMISOS
GRANT CONNECT, RESOURCE TO USER1;
GRANT CONNECT, RESOURCE TO USER2;
GRANT CONNECT, RESOURCE TO USER3;
GRANT CONNECT, RESOURCE TO USER4;

GRANT UNLIMITED TABLESPACE TO USER1;
GRANT UNLIMITED TABLESPACE TO USER2;
GRANT UNLIMITED TABLESPACE TO USER3;
GRANT UNLIMITED TABLESPACE TO USER4;
GRANT UNLIMITED TABLESPACE TO AJENO1;

-- CREAMOS TABLAS
create TABLE USER1.BIGTABLE1_U1 (ID NUMBER(20), NAME varchar2(20));
create TABLE USER2.BIGTABLE1_U2 (ID NUMBER(20), NAME varchar2(20));
create TABLE USER3.BIGTABLE1_U3 (ID NUMBER(20), NAME varchar2(20));
create TABLE USER4.BIGTABLE1_U4 (ID NUMBER(20), NAME varchar2(20));
create TABLE AJENO1.BIGTABLE1_AJ1 (ID NUMBER(20), NAME varchar2(20));
create TABLE AJENO1.BIGTABLE2_AJ1 (ID NUMBER(20), NAME varchar2(20));

create TABLE USER3.BIGTABLE2_U3 (ID NUMBER(20), NAME varchar2(20)) TABLESPACE COMUNTS;
create TABLE USER4.BIGTABLE2_U4 (ID NUMBER(20), NAME varchar2(20)) TABLESPACE COMUNTS;

insert into USER1.BIGTABLE1_U1 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into USER2.BIGTABLE1_U2 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into USER3.BIGTABLE1_U3 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into USER4.BIGTABLE1_U4 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into AJENO1.BIGTABLE1_AJ1 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into AJENO1.BIGTABLE2_AJ1 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into USER3.BIGTABLE2_U3 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into USER4.BIGTABLE2_U4 select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;