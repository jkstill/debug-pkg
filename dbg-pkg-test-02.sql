
@@plsql-init

set serveroutput on format wrapped size unlimited

declare
	v_client_info varchar2(128);
	v_client_module varchar2(128);
	v_client_action varchar2(128);
	c_msg clob;
begin

	c_msg := 'This is a message for testing the DBG package';

	--enable debug output
	dbg.debug_enable;

	-- changing header and footer character takes effect only
	-- if dbg.debug_print has not previously been called

	dbg.debug_print('This is a test of the debug package');

	-- now log something


	-- v$session.client_info
	dbms_application_info.set_client_info('Test Client Info');

	dbms_application_info.set_module(
		module_name => 'Test Client Info: Module',
		action_name => 'Test Client Info: Action 1'
	);

	dbms_application_info.read_client_info(v_client_info);
	dbms_application_info.read_module(v_client_module, v_client_action);

	--dbms_output.put_line('client info: ' || v_client_info);
	--dbms_output.put_line('module info: ' || v_client_module);
	--dbms_output.put_line('action info: ' || v_client_action);

	dbg.logentry(
		client_info	=> v_client_info,
		module_info => v_client_module,
		action_info => v_client_action,
		tag_in 		=> 'free form search text',
		log_msg_in	=> c_msg
	);


end;
/


-- now select the most recent log entry

select *
from plsql_log
where id = ( select max(id) from plsql_log)
/

