
-- call-depth-test-02.sql
-- use call_depth package to get current call depth
-- using a package rather than an anonymous block

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100

create or replace package call_depth_test
is

	procedure p3;
	procedure p2;
	procedure p1;
	procedure p0;

end;
/

show error package call_depth_test

create or replace package body call_depth_test
is

	i_call_depth integer;

procedure p3 
is
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	-- depth will be 1 higher in stored proc than in anonymous block
	if i_call_depth != 4 then
		dbms_output.put_line(dbms_utility.format_call_stack);
		raise_application_error(-20003,'Incorrect call depth in p3. It should be 4, but was ' || to_char(i_call_depth) );
	end if;
end;

procedure p2
is
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	-- cause failure for testing
	--i_call_depth := 4;
	if i_call_depth != 3 then
		dbms_output.put_line(dbms_utility.format_call_stack);
		raise_application_error(-20002,'Incorrect call depth in p2. It should be 3, but was ' || to_char(i_call_depth) );
	end if;
	p3;
end;

procedure p1
is
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	if i_call_depth != 2 then
		dbms_output.put_line(dbms_utility.format_call_stack);
		raise_application_error(-20001,'Incorrect call depth in p1. It should be 2, but was ' || to_char(i_call_depth) );
	end if;
	p2;
end;

procedure p0
is 
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	-- cause failure for testing
	--i_call_depth := 2;
	if i_call_depth != 1 then
		dbms_output.put_line(dbms_utility.format_call_stack);
		raise_application_error(-20000,'Incorrect call depth in p0. It should be 1, but was ' || to_char(i_call_depth) );
	end if;
	p1;
end;

begin
	null;
end;
/

show error package body call_depth_test

exec call_depth_test.p0


