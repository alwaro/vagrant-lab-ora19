-- procesos.sql
-- ---------------------------------------
-- Fecha: Desconocido
-- Autor: Desconocido
-- ---------------------------------------
col RESOURCE_NAME for a40
prompt MOSTRANDO PROCESOS ACTUALES, ALCANZADOS DESDE EL ARRANQUE Y MAXIMOS PERMITIDOS
PROMPT
select * from v$resource_limit where resource_name = 'processes';




