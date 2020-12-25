
-- dbg-pkg-test-03.sql
-- use call_depth package to get current call depth

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100


declare

procedure p3
is
begin
	dbg.debug_print('This is p3');
	dbms_output.put_line('Depth: ' || call_depth.get_depth);
end;

procedure p2
is
begin
	dbg.debug_print('This is p2');
	dbms_output.put_line('Depth: ' || call_depth.get_depth);
	p3;
end;

procedure p1
is
begin
	dbg.debug_print('This is p1');
	dbms_output.put_line('Depth: ' || call_depth.get_depth);
	p2;
end;

begin
	dbg.debug_enable;
	dbg.debug_print('This is main');
	dbms_output.put_line('Depth: ' || call_depth.get_depth);
	p1;
end;
/


