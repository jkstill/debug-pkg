
-- call-depth.sql
-- 2020-12-23 Jared Still  jkstill@gmail.com
-- use dbms_utility.format_call_stack to get a depth
-- for 12c+ use utl_stack package
-- this is handled via :
--   $if dbms_db_version.version <= 11 $then

@@plsql-init

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100

create or replace package call_depth
authid definer
is
	
	function get_depth return integer;
	-- the 'who' functions must be called immediately after calling call_depth
	function who_am_i return varchar2;
	function who_called_me return varchar2;

end;
/

show error package call_depth


create or replace package body call_depth
is

	-- global vars set by get_depth
	-- use the who_am_i and who_called_me functions
	-- immediately after calling get_depth
	v_who_am_i varchar2(120) := 'NA';
	v_who_called_me varchar2(120) := 'NA';


-- must be called immediately after calling call_depth
function who_am_i return varchar2
is
begin
	return v_who_am_i;
end;

-- must be called immediately after calling call_depth
function who_called_me return varchar2
is
begin
	return v_who_called_me;
end;

$if dbms_db_version.version <= 11 or $$mode11g $then

function get_depth return integer
is

	type t_stack_lines is record (line varchar2(1024));
	type t_stack_rows is table of t_stack_lines index by pls_integer;
	t_stack_tab t_stack_rows;
	i_stack_line_idx integer;

	stack_msg clob;

	type t_line_begin is table of integer index by pls_integer;
	t_line_begin_tab t_line_begin;

	-- look for line terminators
	-- just looking for LF(linux) at this time
	-- should work for windows as well, as it is CRLF

	i_stack_len integer;
	i_stack_idx integer := 1;
	v_curr_chr varchar2(1);
	b_get_next_line boolean := false;
	v_line varchar2(256);
	i_line_start integer;
	i_rev_line_end integer;
	i_stack_depth integer := -2;
begin
 
	stack_msg := dbms_utility.format_call_stack;

	--dbms_output.put_line('call_depth()');
	i_stack_len := dbms_lob.getlength(stack_msg);
	
	-- yeah, this is brute force
	for i in 1 .. i_stack_len
	loop
		
		v_curr_chr := dbms_lob.substr(stack_msg,1,i);
		--dbms_output.put_line('curr chr: ' || ascii(v_curr_chr));
		-- this is the end of a line
		if v_curr_chr = chr(10) then
			t_line_begin_tab(i_stack_idx) := i;
			i_stack_idx := i_stack_idx + 1;
			--dbms_output.put_line('found LF terminator');
		else
			--dbms_output.put_line('struck out!');
			null;
		end if;
	end loop;

	--/*
	i_line_start := 1;
	i_stack_line_idx := 1;
	-- line ending positions
	for idx in t_line_begin_tab.first .. t_line_begin_tab.last
	loop
		i_rev_line_end := t_line_begin_tab(idx);

		--dbms_output.put_line('i_line_start: ' || i_line_start);
		--dbms_output.put_line('i_rev_line_end: ' || i_rev_line_end);

		v_line := dbms_lob.substr(stack_msg, i_rev_line_end-i_line_start, i_line_start);
		i_line_start := t_line_begin_tab(idx)+1;

		-- i_stack_idx: index into the lines in format_call_stack, including headers
		-- idx: index into the array of calls
		-- the line
		--dbms_output.put_line('i_stack_line_idx - idx - line: ' || idx || ' : ' || i_stack_line_idx || ' : ' ||  v_line);

		if v_line like '0x%' then
			--dbms_output.put_line('i_stack_line_idx - line: ' || i_stack_line_idx || ' : ' ||  v_line);
			t_stack_tab(i_stack_line_idx).line := v_line;
			i_stack_depth := i_stack_depth + 1;
			i_stack_line_idx := i_stack_line_idx + 1;
		end if;

	end loop;

	/*
	for i in t_stack_tab.first .. t_stack_tab.last
	loop
		--dbms_output.put_line('t_stack_tab i - line: ' || i || ' - ' ||  t_stack_tab(i).line );
	end loop;
	*/

	/*

     call stacks look different for anonymous blocks than for all stored code

	  here is a set of functions in an anonymous block, p1 - p3, all being called from the body of the code
	  (see call-depth-test-01.sql) only body and p1 are shown

      The caller (anonymous block) is the 2nd line in the data)

      i_stack_line_idx - idx - line: 1 : 1 : ----- PL/SQL Call Stack -----
      i_stack_line_idx - idx - line: 2 : 1 :   object      line  object
      i_stack_line_idx - idx - line: 3 : 1 :   handle    number  name
      i_stack_line_idx - idx - line: 4 : 1 : 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
==>>  i_stack_line_idx - idx - line: 5 : 2 : 0x804942f8        40  anonymous block
      t_stack_tab i - line: 1 - 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
      t_stack_tab i - line: 2 - 0x804942f8        40  anonymous block
      i_stack_depth: 0

      i_stack_line_idx - idx - line: 1 : 1 : ----- PL/SQL Call Stack -----
      i_stack_line_idx - idx - line: 2 : 1 :   object      line  object
      i_stack_line_idx - idx - line: 3 : 1 :   handle    number  name
      i_stack_line_idx - idx - line: 4 : 1 : 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
==>>  i_stack_line_idx - idx - line: 5 : 2 : 0x804942f8        32  anonymous block
      i_stack_line_idx - idx - line: 6 : 3 : 0x804942f8        46  anonymous block
      t_stack_tab i - line: 1 - 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
      t_stack_tab i - line: 2 - 0x804942f8        32  anonymous block
      t_stack_tab i - line: 3 - 0x804942f8        46  anonymous block
      i_stack_depth: 1


      Now the stack from all stored code:

      The caller here is the 3rd line in the data

      i_stack_line_idx - idx - line: 1 : 1 : ----- PL/SQL Call Stack -----
      i_stack_line_idx - idx - line: 2 : 1 :   object      line  object
      i_stack_line_idx - idx - line: 3 : 1 :   handle    number  name
      i_stack_line_idx - idx - line: 4 : 1 : 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
      i_stack_line_idx - idx - line: 5 : 2 : 0x77dd8e28        49  package body JKSTILL.CALL_DEPTH_TEST.P0
==>>  i_stack_line_idx - idx - line: 6 : 3 : 0x77bc4778         1  anonymous block
      t_stack_tab i - line: 1 - 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
      t_stack_tab i - line: 2 - 0x77dd8e28        49  package body JKSTILL.CALL_DEPTH_TEST.P0
      t_stack_tab i - line: 3 - 0x77bc4778         1  anonymous block
      who_am_i: JKSTILL.CALL_DEPTH_TEST.P0
      i_stack_depth: 1
      i_stack_line_idx - idx - line: 1 : 1 : ----- PL/SQL Call Stack -----
      i_stack_line_idx - idx - line: 2 : 1 :   object      line  object
      i_stack_line_idx - idx - line: 3 : 1 :   handle    number  name
      i_stack_line_idx - idx - line: 4 : 1 : 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
      i_stack_line_idx - idx - line: 5 : 2 : 0x77dd8e28        36  package body JKSTILL.CALL_DEPTH_TEST.P1
==>>  i_stack_line_idx - idx - line: 6 : 3 : 0x77dd8e28        56  package body JKSTILL.CALL_DEPTH_TEST.P0
      i_stack_line_idx - idx - line: 7 : 4 : 0x77bc4778         1  anonymous block
      t_stack_tab i - line: 1 - 0x791de1e8        36  package body JKSTILL.CALL_DEPTH.GET_DEPTH
      t_stack_tab i - line: 2 - 0x77dd8e28        36  package body JKSTILL.CALL_DEPTH_TEST.P1
      t_stack_tab i - line: 3 - 0x77dd8e28        56  package body JKSTILL.CALL_DEPTH_TEST.P0
      t_stack_tab i - line: 4 - 0x77bc4778         1  anonymous block
      who_am_i: JKSTILL.CALL_DEPTH_TEST.P1
      i_stack_depth: 2
      i_call_depth: 2

      
      When the 2nd line in the array is 'anonymous block' I think it is safe to assume the caller is an anonymous block.

      Compare call-depth-test-01.sql and call-depth-test-02.sql

	*/

	-- pattern to get final word in string
	-- substr(string,instr(rtrim(string),' ',-1,1)+1)
	v_who_am_i := substr(t_stack_tab(2).line,instr(rtrim(t_stack_tab(2).line),' ',-1,1)+1);
	-- see previous comments
	if (v_who_am_i = 'block' ) then
		i_stack_depth := i_stack_depth + 1;
	end if;

	if (v_who_am_i = 'block' and t_stack_tab.last = 2) then
		v_who_called_me := 'NA';
	else
		v_who_called_me := substr(t_stack_tab(3).line,instr(rtrim(t_stack_tab(3).line),' ',-1,1)+1);
	end if;

	--dbms_output.put_line('call_depth.who_am_i: ' || v_who_am_i);
	--dbms_output.put_line('call_depth.who_called_me: ' || v_who_called_me);
	--dbms_output.put_line('i_stack_depth: ' || i_stack_depth);

	return i_stack_depth;

	--*/
end;

$else

function get_depth return integer
is
	i_depth integer;

	-- the caller is #3 in the arrary from utl_call_stack.subprogram
	-- when called from the body of an anonymous block there are only 2 records in the array
	-- then this will happen
	-- ORA-64610: bad depth indicator
	e_bad_depth exception;
	pragma exception_init(e_bad_depth,-64610);
	
begin
	--dbms_output.put_line('get_depth 12c+');
	i_depth := utl_call_stack.dynamic_depth -1;
	--dbms_output.put_line('get_depth - i_depth: ' || to_char(i_depth));
	v_who_am_i := utl_call_stack.concatenate_subprogram( utl_call_stack.subprogram(2));

	/*
	dbms_output.put_line('==>> get_depth - full stack:');
	for i in 1 .. utl_call_stack.dynamic_depth
	loop
		dbms_output.put_line('  ==>> caller stack: ' || to_char(i) || ' : ' || utl_call_stack.concatenate_subprogram( utl_call_stack.subprogram(i)));
	end loop;
	*/

	--dbms_output.put_line('get_depth - who am i: ' || v_who_am_i);

	begin
		v_who_called_me := utl_call_stack.concatenate_subprogram( utl_call_stack.subprogram(3));
	exception
	when e_bad_depth then
		v_who_called_me := 'NA';
	end;

	-- account for differences in stack between stored procedure and anonymous block
	-- see comments earlier in this code
	if not v_who_am_i like '__anonymous_block%' then
		i_depth := i_depth - 1;
	end if;

	return i_depth;

end;
$end

begin
	null;
end;
/
show error package body call_depth


