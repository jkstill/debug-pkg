
-- demo-02.sql
-- use call_depth package to get current call depth

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100

declare

	$if dbms_db_version.version <= 11 $then
		c_stack clob;
	$end

procedure p3 
is
	$if dbms_db_version.version <= 11 $then
		c_stack clob;
	$end
begin
	dbms_output.put_line('      ### P3 ###');
	dbms_output.put_line(dbms_utility.format_call_stack);
	-- implicit conversion
	$if dbms_db_version.version <= 11 $then
		c_stack := dbms_utility.format_call_stack;
		dbms_output.put_line('current stack depth: ' || call_depth.get_depth(c_stack) );
	$else
		dbms_output.put_line('current stack depth: ' || call_depth.get_depth() );
	$end
end;

procedure p2
is
	$if dbms_db_version.version <= 11 $then
		c_stack clob;
	$end
begin
	dbms_output.put_line('  ### P2 ###');
	dbms_output.put_line(dbms_utility.format_call_stack);
	$if dbms_db_version.version <= 11 $then
		c_stack := dbms_utility.format_call_stack;
		dbms_output.put_line('current stack depth: ' || call_depth.get_depth(c_stack) );
	$else
		dbms_output.put_line('current stack depth: ' || call_depth.get_depth() );
	$end
	p3;
end;

procedure p1
is
	$if dbms_db_version.version <= 11 $then
		c_stack clob;
	$end
begin
	dbms_output.put_line('### P1 ###');
	dbms_output.put_line(dbms_utility.format_call_stack);
	$if dbms_db_version.version <= 11 $then
		c_stack := dbms_utility.format_call_stack;
		dbms_output.put_line('current stack depth: ' || call_depth.get_depth(c_stack) );
	$else
		dbms_output.put_line('current stack depth: ' || call_depth.get_depth() );
	$end
	p2;
end;

begin

	$if dbms_db_version.version <= 11 $then
		c_stack := dbms_utility.format_call_stack;
		dbms_output.put_line('root stack depth: ' || call_depth.get_depth(c_stack) );
	$else
		dbms_output.put_line('root stack depth: ' || call_depth.get_depth() );
	$end
	p1;

end;
/


