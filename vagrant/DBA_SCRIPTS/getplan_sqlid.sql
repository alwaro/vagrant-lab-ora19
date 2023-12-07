-- getplan_sqlid.sql
-- ---------------------------------------
-- Fecha: Desconocido
-- Autor: Desconocido
-- ---------------------------------------
set lines 150
select * from table(dbms_xplan.display_cursor('&sql_id','&child_no','typical'))
/





