-- ===============================================================
-- NAME: pdb.sql
-- DESCRIPTION: Cambio a pdb o cdb$root actualizando el prompt
-- USAGE: Execute
-- AUTHOR: Alvaro Anaya
-- ---------------------------------------------------------------
set verify off
DEF pdb_name='&1';
alter session set container=&pdb_name;
SELECT sys_context('USERENV','CON_NAME') pdb_name FROM dual;
SET sqlprompt "&_USER.@&pdb_name.> "
undef pdb_name;
PROMPT OBJETOS VISIBLES DESDE EL AMBITO ACTUAL
PROMPT ===========================================================================
show pdbs;