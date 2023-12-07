-- getplan_query.sql
-- ---------------------------------------
-- Fecha: Desconocido
-- Autor: Desconocido
-- ---------------------------------------
set lines 200
set pages 200
explain plan for
'&query';

select * from table(dbms_xplan.display());




