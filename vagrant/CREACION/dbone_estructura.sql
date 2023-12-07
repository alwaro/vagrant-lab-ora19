-- CONFIGURAMOS PARAMETRO 
alter system set db_create_file_dest='/opt/oracle/oradata' scope=both;

-- CREAMOS TABLESPACES
CREATE BIGFILE TABLESPACE MANOLO_TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;
CREATE BIGFILE TABLESPACE PACO_TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;
CREATE BIGFILE TABLESPACE COMUNITARIO_TS DATAFILE SIZE 10M AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED;


-- CREAMOS USUAROS
CREATE USER MANOLO IDENTIFIED BY MANOLO DEFAULT TABLESPACE MANOLO_TS;
CREATE USER PACO IDENTIFIED BY PACO DEFAULT TABLESPACE PACO_TS;

-- DAMOS QUOTAS Y PERMISOS
GRANT CONNECT, RESOURCE TO MANOLO;
GRANT CONNECT, RESOURCE TO PACO;

GRANT UNLIMITED TABLESPACE TO MANOLO;
GRANT UNLIMITED TABLESPACE TO PACO;

-- CREAMOS TABLAS MANOLO
create TABLE MANOLO.BIGTABLE1_MANOLO (ID NUMBER(20), NAME varchar2(20));
create TABLE MANOLO.BIGTABLE2_MANOLO (ID NUMBER(20), NAME varchar2(20)) TABLESPACE COMUNITARIO_TS;

-- CREAMOS TABLAS PACO
create TABLE PACO.BIGTABLE1_PACO (ID NUMBER(20), NAME varchar2(20));


insert into MANOLO.BIGTABLE1_MANOLO select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into MANOLO.BIGTABLE2_MANOLO select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

insert into PACO.BIGTABLE1_PACO select rownum, 'Name'||rownum from dual
  connect by rownum<=100000;
commit;

exit;