-- tbs_full.sql
-- aka la query de los ts del toad
-- ----------------------------------------------
-- Fecha: Desconocido
-- Autor: Desconocido
-- ---------------------------------------
select  a.tablespace_name,
       round(a.bytes_alloc / 1024 / 1024) megs_alloc,
       round(nvl(b.bytes_free, 0) / 1024 / 1024) megs_free,
       round((a.bytes_alloc - nvl(b.bytes_free, 0)) / 1024 / 1024) megs_used,
       round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100) Pct_Free,
       100 - round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100) Pct_used,
       round(maxbytes/1048576) Max,
      c.status, c.contents
from  ( select  f.tablespace_name,
               sum(f.bytes) bytes_alloc,
               sum(decode(f.autoextensible, 'YES',f.maxbytes,'NO', f.bytes)) maxbytes
        from dba_data_files f
        group by tablespace_name) a,
      ( select  f.tablespace_name,
               sum(f.bytes)  bytes_free
        from dba_free_space f
        group by tablespace_name) b,
      dba_tablespaces c
where a.tablespace_name = b.tablespace_name (+)
and a.tablespace_name = c.tablespace_name
union all
select h.tablespace_name,
       round(sum(h.bytes_free + h.bytes_used) / 1048576) megs_alloc,
       round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / 1048576) megs_free,
       round(sum(nvl(p.bytes_used, 0))/ 1048576) megs_used,
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / sum(h.bytes_used + h.bytes_free)) * 100) Pct_Free,
       100 - round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / sum(h.bytes_used + h.bytes_free)) * 100) pct_used,
       round(sum(decode(f.autoextensible, 'YES', f.maxbytes, 'NO', f.bytes) / 1048576)) max,
      c.status, c.contents
from   sys.v_$TEMP_SPACE_HEADER h,
       (select tablespace_name, file_id, sum(bytes_used) bytes_used
        from gv$temp_extent_pool
        group by tablespace_name, file_id) p,
       dba_temp_files f,
      dba_tablespaces c
where  p.file_id(+) = h.file_id
and    p.tablespace_name(+) = h.tablespace_name
and    f.file_id = h.file_id
and    f.tablespace_name = h.tablespace_name
and f.tablespace_name = c.tablespace_name
group by h.tablespace_name, c.status, c.contents
ORDER BY 1;





