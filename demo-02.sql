
-- demo-02.sql
-- use call_depth package to get current call depth

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100

declare

procedure p3 
is
begin
	dbms_output.put_line('      ### P3 ###');
	dbms_output.put_line(dbms_utility.format_call_stack);
	dbms_output.put_line('current stack depth: ' || call_depth.get_depth() );
end;

procedure p2
is
begin
	dbms_output.put_line('  ### P2 ###');
	dbms_output.put_line(dbms_utility.format_call_stack);
	dbms_output.put_line('current stack depth: ' || call_depth.get_depth() );
	p3;
end;

procedure p1
is
begin
	dbms_output.put_line('### P1 ###');
	dbms_output.put_line(dbms_utility.format_call_stack);
	dbms_output.put_line('current stack depth: ' || call_depth.get_depth() );
	p2;
end;

begin

	dbms_output.put_line('root stack depth: ' || call_depth.get_depth() );
	p1;

end;
/


