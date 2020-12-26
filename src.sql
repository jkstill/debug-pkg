
set linesize 200 trimspool on
set pagesize 500
col line format 99999
col text format a180

select line, text
from dba_source
where owner = 'JKSTILL'
and name = 'CALL_DEPTH'
order by type,line
/
