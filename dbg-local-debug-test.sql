
-- test local debug

declare

	procedure p1 ( debug_in boolean := false )
	is
	begin
		dbg.debug_local_set(debug_in);

		dbg.pl(rpad('=',80,'='));
		dbg.pl('P1: called with DEBUG: ' || case debug_in when false then 'FALSE' else 'TRUE' end);

		if dbg.debug_status then
			dbg.pl('P1: Global debug enabled');
		else
			dbg.pl('P1: Global debug DISABLED');
		end if;

		if dbg.get_local_debug_status then
			dbg.pl('P1: Local debug enabled');
		else
			dbg.pl('P1: Local debug DISABLED');
		end if;

		dbg.debug_local_reset;

	end;

	procedure p2 ( debug_in boolean := false )
	is
	begin
		dbg.debug_local_set(debug_in);

		dbg.pl(rpad('=',80,'='));
		dbg.pl('P2: called with DEBUG: ' || case debug_in when false then 'FALSE' else 'TRUE' end);

		if dbg.debug_status then
			dbg.pl('P2: Global debug enabled');
		else
			dbg.pl('P2: Global debug DISABLED');
		end if;

		if dbg.get_local_debug_status then
			dbg.pl('P2: Local debug enabled');
		else
			dbg.pl('P2: Local debug DISABLED');
		end if;

		dbg.debug_local_reset;

	end;


begin
	p1;
	p1(true);
	p1(false);
	p2(true);
	p1(false);
end;
/

