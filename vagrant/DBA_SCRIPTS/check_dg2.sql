-- check_dg2.sql
-- ---------------------------------------
-- Fecha: Desconocido
-- Autor: Desconocido
-- ---------------------------------------
set lines 150;
select sequence#, applied, to_char(first_time,'dd/mm/yyyy hh24:mi:ss'),
to_char(next_time,'dd/mm/yyyy hh24:mi:ss'), archived, status
from v$archived_log order by sequence#;





