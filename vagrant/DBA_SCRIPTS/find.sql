-- find.sql
-- ---------------------------------------
-- Fecha: 2018
-- Autor: Alvaro Anaya
-- ---------------------------------------
set verify off
DEF objeto='&1';
col OBJECT_NAME format a45
spoo search_&&objeto.log
select owner, object_name, object_type,CREATED,STATUS, LAST_DDL_TIME from dba_objects where object_name like '%&&objeto%';
undef objeto;
spoo off





