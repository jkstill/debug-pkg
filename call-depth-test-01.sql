

-- call-depth-test-01.sql
-- use call_depth package to get current call depth

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100

declare

	i_call_depth integer;

procedure p3 
is
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	dbms_output.put_line('p3 depth     :    ' || to_char(i_call_depth));
	dbms_output.put_line('     who am i: ' || call_depth.who_am_i);
	dbms_output.put_line('   who called: ' || call_depth.who_called_me);
	if i_call_depth != 4 then
		raise_application_error(-20003,'Incorrect call depth in p3. It should be 4, but was ' || to_char(i_call_depth) );
	end if;
end;

procedure p2
is
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	dbms_output.put_line('p2 depth     :    ' || to_char(i_call_depth));
	dbms_output.put_line('     who am i: ' || call_depth.who_am_i);
	dbms_output.put_line('   who called: ' || call_depth.who_called_me);
	-- cause failure for testing
	--i_call_depth := 4;
	if i_call_depth != 3 then
		raise_application_error(-20002,'Incorrect call depth in p2. It should be 3, but was ' || to_char(i_call_depth) );
	end if;
	p3;
end;

procedure p1
is
	i_call_depth integer;
begin
	i_call_depth := call_depth.get_depth;
	dbms_output.put_line('p1 depth     :    ' || to_char(i_call_depth));
	dbms_output.put_line('     who am i: ' || call_depth.who_am_i);
	dbms_output.put_line('   who called: ' || call_depth.who_called_me);
	if i_call_depth != 2 then
		raise_application_error(-20001,'Incorrect call depth in p1. It should be 2, but was ' || to_char(i_call_depth) );
	end if;
	p2;
end;

begin
	i_call_depth := call_depth.get_depth;
	dbms_output.put_line('main depth   :    ' || to_char(i_call_depth));
	dbms_output.put_line('     who am i: ' || call_depth.who_am_i);
	dbms_output.put_line('   who called: ' || call_depth.who_called_me);
	-- cause failure for testing
	--i_call_depth := 1;
	if i_call_depth != 1 then
		raise_application_error(-20000,'Incorrect call depth in p0. It should be 1, but was ' || to_char(i_call_depth) );
	end if;
	p1;
end;
/


