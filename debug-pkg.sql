
-- debug-pkg.sql
-- 2020-12-23 Jared Still  jkstill@gmail.com
-- provide some simple debugging messages
-- and logging to a table
-- not a real debugger - just messages indented per call depth

/*

 the names are short here 
 part of the reason for some routines is to avoid putting dbms_output.put_line() all over the place.

 Also to get some more formatting and information

 This package is designed to provide some simple debugging tools, nothing extravagant

 There is a dependency on the call_depth package.

*/

@@plsql-init

create or replace package dbg
authid definer
is

	-- debug output control
	procedure debug_enable;
	procedure debug_disable;
	procedure debug_print(text_in clob);
	function debug_status return boolean;

	function get_local_debug_status return boolean;
   procedure debug_local_set( b_debug_status_in boolean);
   procedure debug_local_reset;


	procedure p (text_in clob);
	procedure pl (text_in clob);

	function header_chr_get return varchar2; -- character used for banner
	procedure header_chr_set(header_chr_in varchar2);

	function footer_chr_get return varchar2; -- character used for banner
	procedure footer_chr_set(footer_chr_in varchar2);

	function banner_len_get return integer; -- banner length
	procedure banner_len_set(banner_len_in integer);

	v_header varchar2(200) := null;  -- once set in get_debug_banner, it is not changed for the rest of the session
	v_footer varchar2(200) := null;  -- once set in get_debug_banner, it is not changed for the rest of the session
	v_debug_pfx varchar2(64) := null; -- once set in get_debug_banner, it is not changed for the rest of the session

	function pad_get return varchar2; -- returns the current character used for padding debug output
	procedure pad_set( pad_chr_in varchar2); -- a single character used to pad debug output
	function indent_get return integer; -- returns the number of padding characters to use per output level (based on call depth)
	procedure indent_set(indent_in integer); -- set the number of padding characters to use per output level (based on call depth)

	-- simple logging  <<-------------------------------<
	-- yes, I do know about log4plsql, and have used it |
	-- >------------------------------------------------^

	-- creates the log table in the creators schema
	-- adjust value of v_tablespace in the package body to add tablespace if needed
	-- no indexes are created - create them as needed
	procedure log_init;

	-- timestamp and user automatically included
	-- use dbms_application_info for logging
	-- the varchar2 values are limited to 64 bytes (assuming single byte characters)
	procedure logentry(
		client_info varchar2 default null
		, module_info varchar2 default null
		, action_info varchar2 default null
		, tag_in varchar2 default null
		, log_msg_in clob
	);

	$if $$develop $then
	function table_exists return boolean;
	$end

end;
/

show error package dbg


create or replace package body dbg
is
	v_sql clob;
	v_tablespace varchar2(30) := null;
	v_log_table varchar2(30) := 'PLSQL_LOG'; -- change this to whatever
	v_log_seq varchar2(30) := 'PLSQL_LOG_SEQ'; -- change this to whatever

	v_pad_chr varchar2(1) := ' '; -- single space
	i_indent_level integer := 2;  
	v_header_chr varchar2(1) := '=';
	v_footer_chr varchar2(1) := '-';
	v_banner_len integer := 60;
	b_debug boolean := false;
	b_debug_local boolean;

	-- exceptions
	e_object_exists exception;
	pragma exception_init(e_object_exists,-955);

	e_table_not_found exception;
	pragma exception_init(e_table_not_found,-942);

--== Debug Routines ==--
procedure debug_enable
is
begin
	b_debug := true;
end;

procedure debug_disable
is
begin
	b_debug := false;
end;

function debug_status return boolean
is
begin
	return b_debug;
end;

function get_debug_header return varchar2
is
begin
	return rpad(header_chr_get,banner_len_get,header_chr_get);
end;

function get_debug_footer return varchar2
is
begin
	return rpad(footer_chr_get,banner_len_get,footer_chr_get);
end;

function get_debug_pfx return varchar2
is
begin
	-- subtract two from depth to account for calling this and the parent debug_print()
	return rpad(pad_get,indent_get * call_depth.get_depth -2,pad_get);
end;

/*

 debug_set and debug_reset are for localized debug enable

 for example: you want to call a procedure that is not doing what expected,
 but only show debugging output for that one - not globally enabled debug

 procedure xyz (
 	name_in varchar2,
	debug_in boolean default false
 ) is
 begin
   debug_local_set(debug_in);
   
	some code...

	dbg.debug_print('print something');

	more code...

	dbg.debug_print('print something');

	debug_local_reset;
 end;

 Keep in mind the global debug stats will cascade to called functions and procedures

*/

function get_local_debug_status return boolean
is
begin
	return b_debug_local;
end;

procedure debug_local_set( b_debug_status_in boolean)
is
begin
	-- prevents resetting debug if it was set globally
	if debug_status then
		b_debug_local := false;
	else
		b_debug_local := b_debug_status_in;
		if b_debug_status_in then
			--dbg.pl('debug_local_set: setting Global Debug TRUE');
			dbg.debug_enable;
		end if;
	end if;
end;

procedure debug_local_reset
is
begin
	-- prevents resetting debug if it was set globally
	if get_local_debug_status then
		--dbg.pl('debug_local_reset: Local Debug FALSE');
		--dbg.pl('debug_local_reset: setting Global Debug FALSE');
		dbg.debug_disable;
	end if;
end;


procedure debug_print(text_in clob)
is
begin

	-- these header and footer are set only once
	if v_header is null then
		v_header := get_debug_header;
	end if;

	if v_footer is null then
		v_footer := get_debug_footer;
	end if;
	
	-- indent the text being printed
	v_debug_pfx :=  get_debug_pfx;

	if debug_status then
		pl(v_header);
		pl(v_debug_pfx || text_in);
		pl(v_footer);
	end if;
end;

--== Print Routines ==--
procedure p (text_in clob)
is
begin
	dbms_output.put(text_in);
end;

procedure pl (text_in clob)
is
begin
	p(text_in);
	dbms_output.new_line;
end;

--== Padding Routines ==--

function header_chr_get return varchar2
is
begin
	return v_header_chr;
end;

procedure header_chr_set(header_chr_in varchar2)
is
begin
	v_header_chr := header_chr_in;
end;

function footer_chr_get return varchar2
is
begin
	return v_footer_chr;
end;

procedure footer_chr_set(footer_chr_in varchar2)
is
begin
	v_footer_chr := footer_chr_in;
end;

function banner_len_get return integer
is
begin
	return v_banner_len;
end;

procedure banner_len_set(banner_len_in integer)
is
begin
	v_banner_len := banner_len_in;
end;

function pad_get return varchar2 -- returns the current character used for padding debug output
is
begin
		return v_pad_chr;
end;

procedure pad_set( pad_chr_in varchar2) -- a single character used to pad debug output
is
begin
		v_pad_chr := pad_chr_in;
end;

function indent_get return integer -- returns the number of padding characters to use per output level (based on call depth)
is
begin
		return i_indent_level;
end;

procedure indent_set(indent_in integer) -- set the number of padding characters to use per output level (based on call depth)
is
begin
		i_indent_level := indent_in;
end;

--== Create a log entry ==--
procedure logentry(
	client_info varchar2 default null
	, module_info varchar2 default null
	, action_info varchar2 default null
	, tag_in varchar2 default null
	, log_msg_in clob
)
is
	i_id pls_integer;
	pragma autonomous_transaction;
	i_error_code integer;
begin

	v_sql := 'select ' || v_log_seq || '.nextval from dual';

	execute immediate v_sql into i_id;
	--pl('i_id: ' || to_char(i_id));

	v_sql := 'insert into ' || v_log_table || ' values( '
		|| ':id,'
		|| ':timestamp,'
		|| ':client_info,'
		|| ':module_info,'
		|| ':action_info,'
		|| ':tags,'
		|| ':log_msg'
		|| ')';

	execute immediate v_sql using 
		i_id, systimestamp, 
		substr(client_info,1,64), 
		substr(module_info,1,64), 
		substr(action_info,1,64), 
		substr(tag_in,1,64), 
		log_msg_in;

	commit;

exception
when others then
	i_error_code := sqlcode;
	pl('Error encountered in logentry with "' || v_sql || '"');
	pl('Error: ' || to_char(i_error_code));
	raise ;
end;

--== Initialize the log table and sequnce ==--
--== You can create indexes as needed ==--
procedure log_init
is
	v_current_action varchar2(128);
	i_error_code integer;
	pragma autonomous_transaction;
begin
	v_current_action := 'create sequence ' || v_log_seq;
	v_sql := v_current_action;

	begin
		execute immediate v_sql;
	exception
	when e_object_exists then
		null;
	end;

	if not table_exists then

		v_current_action := 'create table ' || v_log_table;

		v_sql := v_current_action || ' ( ';
		v_sql := v_sql 
			|| 'id number,'
			|| 'log_timestamp timestamp,'
			|| 'client_info varchar2(64),'
			|| 'module_info varchar2(64),'
			|| 'action_info varchar2(64),'
			|| 'tags varchar2(64),'
			|| 'msg clob not null'
			|| ')';

		execute immediate v_sql;

	end if;

exception
when others then
	i_error_code := sqlcode;
	pl('Error encountered in log_init with "' || v_current_action || '"');
	pl('Error: ' || to_char(i_error_code));
	raise;
end;

--== Check if the table exists ==--
--== This could easily be changed to object_exists ==--
function table_exists return boolean
is
	cursor csr_tab_exist (table_name_in varchar2)
	is
	select count(*) tabcount
	from user_tables
	where table_name = table_name_in;

	i_tab_count integer;

begin
	open csr_tab_exist(v_log_table); -- specified in package body global
	fetch csr_tab_exist into i_tab_count;
	close csr_tab_exist;

	if i_tab_count > 0 then 
		return true;
	else
		return false;
	end if;
	
end;

begin
	-- called on first invocation
	log_init;
exception
when others then -- just a stub for exception handling
	raise;
end;
/


show error package body dbg














