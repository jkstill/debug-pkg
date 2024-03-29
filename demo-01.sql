
-- demo-01.sql
-- use dbms_utility.format_call_stack to get a depth
-- for 12c+ use utl_call_stack package
-- this is handled via :
--   $if dbms_db_version.version <= 11 $then

set serveroutput on format wrapped size unlimited
set linesize 250 trimspool on
set pagesize 100

declare

	$if dbms_db_version.version <= 11 $then
		c_stack clob;
	$end

$if dbms_db_version.version <= 11 $then

function call_depth ( stack_msg clob ) return integer
is

	--type t_stack_lines is record (line varchar2(1024));
	--type t_stack_rows is table of t_stack_lines index by pls_integer;
	--t_stack_tab t_stack_rows;

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
	i_stack_depth integer := -1;
begin

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
	-- line ending positions
	for idx in t_line_begin_tab.first .. t_line_begin_tab.last
	loop
		i_rev_line_end := t_line_begin_tab(idx);

		--dbms_output.put_line('i_line_start: ' || i_line_start);
		--dbms_output.put_line('i_rev_line_end: ' || i_rev_line_end);

		v_line := dbms_lob.substr(stack_msg, i_rev_line_end-i_line_start, i_line_start);
		i_line_start := t_line_begin_tab(idx)+1;

		if v_line like '0x%' then
			dbms_output.put_line('line: ' || v_line);
			i_stack_depth := i_stack_depth + 1;
		end if;

	end loop;

	--dbms_output.put_line('i_stack_depth: ' || i_stack_depth);
	return i_stack_depth;

	--*/
end;

$else

function call_depth return integer
is
begin
	return utl_call_stack.dynamic_depth-2;
end;
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
		dbms_output.put_line('current stack depth: ' || call_depth(c_stack) );
	$else
		dbms_output.put_line('current stack depth: ' || call_depth() );
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
		dbms_output.put_line('current stack depth: ' || call_depth(c_stack) );
	$else
		dbms_output.put_line('current stack depth: ' || call_depth() );
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
		dbms_output.put_line('current stack depth: ' || call_depth(c_stack) );
	$else
		dbms_output.put_line('current stack depth: ' || call_depth() );
	$end
	p2;
end;

begin

	$if dbms_db_version.version <= 11 $then
		c_stack := dbms_utility.format_call_stack;
		dbms_output.put_line('root stack depth: ' || call_depth(c_stack) );
	$else
		dbms_output.put_line('root stack depth: ' || call_depth() );
	$end
	p1;

end;
/


