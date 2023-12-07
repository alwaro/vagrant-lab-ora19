-- jobs_running.sql
-- ---------------------------------------
-- Fecha: Desconocido
-- Autor: Desconocido
-- ---------------------------------------
set lines 150
set pages 999
select session_id,JOB_NAME,OWNER from  dba_scheduler_running_jobs;





