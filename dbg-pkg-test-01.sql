
@@plsql-init

begin

	null;

	$if $$develop $then
	if dbg.table_exists then
		dbms_output.put_line('table exists');
	else 
		dbms_output.put_line('table does NOT exist');
		dbg.log_init;
	end if;
	$end

end;
/

