PL/SQL Debugging Routines
=========================

Just some things to help with debugging PL/SQL code.

## grants.sql

These grants must be made to the user creating the package.

## call_depth package

It would be useful to know what the current level is in the call stack when debugging.

For Oracle 12c+, that can be obtained via UTL_CALL_STACK.DYNAMIC_DEPTH.

For older versions, it is more difficult.

What this code does is walk through the call stack and look for address lines.

The call depth is 0 based. 

When you build the call_depth package, dbms_db_version.version is used to determine which code to compile.

This has been tested on 11.1 and 19.8 versions of the oracle database.

## plsql-init.sql

This script is called prior to creating the package.
Adjust the values in this script as necessary.


### call-depth.sql

Create the package:
```text
SQL# @call-depth

Package created.

No errors.

Package body created.

No errors.
```
### call_depth subprograms

#### call_depth.get_depth

Returns calling depth from the stack.

The value returned is adjusted so that values match:

- between 11g and 12c+
- whether called from anonymous block or stored procedures

```text
declare
  i_call_depth integer;
begin
  i_call_depth := call_depth.get_depth;
  dbms_output.put_line('depth: ' || to_char(i_call_depth));
end;
/

depth: 1

PL/SQL procedure successfully completed.
 
```

This will not work when called directly from sqlplus:

```text
SQL# select call_depth.get_depth from dual;
select call_depth.get_depth from dual
       *
ERROR at line 1:
ORA-64610: bad depth indicator
ORA-06512: at "SYS.UTL_CALL_STACK", line 19
ORA-06512: at "JKSTILL.CALL_DEPTH", line 218

```

#### call_depth.who_am_i

Returns the name of the current procedure or function.

Note, this must be called immediately following a call to call_depth.get_depth.

```text
declare
  who_am_i varchar2(120);
begin
  who_am_i := call_depth.who_am_i;
  dbms_output.put_line('who_am_i: ' || who_am_i);
end;
SQL# /
who_am_i: __anonymous_block
```

#### call_depth.who_called_me

Returns the name of the calling procedure or function.

Note, this must be called immediately following a call to call_depth.get_depth.

```text
declare
  who_called_me varchar2(120);
begin
  who_called_me := call_depth.who_called_me;
  dbms_output.put_line('who_called_me: ' || who_called_me);
end;
/

who_called_me: NA
```

As this was the body of an anonymous block, there was not caller; hence the NA.

### demo-02.sql

This is a demo of using the call_depth package:

```text
SQL# @demo-02
line: 0x818f3bd8        61  anonymous block
root stack depth: 0
### P1 ###
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
0x818f3bd8        48  anonymous block
0x818f3bd8        66  anonymous block

line: 0x818f3bd8        50  anonymous block
line: 0x818f3bd8        66  anonymous block
current stack depth: 1
  ### P2 ###
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
0x818f3bd8        31  anonymous block
0x818f3bd8        55  anonymous block
0x818f3bd8        66  anonymous block

line: 0x818f3bd8        33  anonymous block
line: 0x818f3bd8        55  anonymous block
line: 0x818f3bd8        66  anonymous block
current stack depth: 2
      ### P3 ###
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
0x818f3bd8        14  anonymous block
0x818f3bd8        38  anonymous block
0x818f3bd8        55  anonymous block
0x818f3bd8        66  anonymous block

line: 0x818f3bd8        17  anonymous block
line: 0x818f3bd8        38  anonymous block
line: 0x818f3bd8        55  anonymous block
line: 0x818f3bd8        66  anonymous block
current stack depth: 3

PL/SQL procedure successfully completed.

```

### call depth differences

The depth of the stack is different when called via anonymous block than when called strictly within stored code.

The value of depth of the current call is adjust to provide a consistent value, whether called from an anonymous block, or a stored procedure.

See these test scripts:

- call-stack-test-01.sql
  - uses an anonymous block
- call-stack-test-02.sql
  - uses a test package

## Debug package DBG

The DBG package is a fairly simple package for debugging output and minimal logging.

The call depth is used to indent the text sent to dbg.debug_print.

Logging messages are created with dbg.logentry.

The default table name for the log table is PLSQL_LOG.  This can be changed in the package body if you like.
No indexes are created on the table - create whatever indexes you need.

The first invocation of dbg.logentry will create the log table if it doesn't already exist, along with a sequence PLSQL_LOG_SEQ.

Following are some tests of the package.

## plsql-init.sql

This script is called prior to creating the package.
Adjust the values in this script as necessary.

## debug-pkg.sql

This is the file used to create the package DBG.

```text
SQL# @debug-pkg.sql 
this line appears only when the develop flag is true
this line appears only when the debug flag is true

PL/SQL procedure successfully completed.


Package created.

No errors.

Package body created.

No errors.

```

### DBG package subprograms

#### procedure debug_enable

Enable debugging output. It is disabled by default.

#### procedure debug_disable

Disable debugging output. It is disabled by default.

#### procedure debug_print

Print the text if debugging is enabled.

```sql
dbg.debug_print('This is a test of the debug package');
```

#### function debug_status 

Returns a boolean indicating the current debug status.

#### procedure p

The same as dbms_output.print, but a bit easier to type.

#### procedure pl

The same as dbms_output.print_line, but a bit easier to type.

#### function header_chr_get

Get the character used to compose the header line used in dbg.debug_print;

#### procedure header_chr_set

Set the character used to compose the header line used in dbg.debug_print.

This will have effect only if called prior to the first call to dbg.debug_print.

#### function footer_chr_get

Get the character used to compose the footer line used in dbg.debug_print;

#### procedure footer_chr_set

Set the character used to compose the footer line used in dbg.debug_print.

This will have effect only if called prior to the first call to dbg.debug_print.

#### function banner_len_get

Get the length used for the header and footer lines.

#### procedure banner_len_set

Get the length used for the header and footer lines.

This will have effect only if called prior to the first call to dbg.debug_print.

#### function pad_get

Get the character used for padding the debug output text.

#### procedure pad_set

Set the character used for padding the debug output text.

#### function indent_get

Get the value for the current indent size.

#### procedure indent_set

Set the value for the indent size.

#### procedure log_init;

Initialize the log table and sequence.

This will be done automatically with the first logentry as well.

#### procedure logentry

Add an entry to the log table.

See `dbg-pkg-test-02.sql` for an example usage.

## dbg-pkg-test-01.sql

Just a simple test of the function that checks for the existence of the log table

```text
SQL# @dbg-pkg-test-01.sql

this line appears only when the develop flag is true
this line appears only when the debug flag is true

PL/SQL procedure successfully completed.

table exists

PL/SQL procedure successfully completed.

```

## dbg-pkg-test-02.sql

This test enables debugging output, and prints a line of debug output.

Next it creates a log entry, and then selects the most recent log entry from the PLSQL_LOG table.

```text
QL# @dbg-pkg-test-02.sql
this line appears only when the develop flag is true
this line appears only when the debug flag is true

PL/SQL procedure successfully completed.

============================================================
  This is a test of the debug package
------------------------------------------------------------

PL/SQL procedure successfully completed.


        ID LOG_TIMESTAMP                                                               CLIENT_INFO                                                      MODULE_INFO
---------- --------------------------------------------------------------------------- ---------------------------------------------------------------- ----------------------------------------------------------------
ACTION_INFO                                                      TAGS                                                             MSG
---------------------------------------------------------------- ---------------------------------------------------------------- --------------------------------------------------------------------------------
       282 24-DEC-20 04.34.45.409620 PM                                                Test Client Info                                                 Test Client Info: Module
Test Client Info: Action 1                                       free form search text                                            This is a message for testing the DBG package


1 row selected.

```

## dbg-pkg-test-03.sql

This script demonstrate the use of call stack depth in debug output.

```text
QL# @dbg-pkg-test-03.sql
============================================================
  This is main
------------------------------------------------------------
Depth: 0
============================================================
    This is p1
------------------------------------------------------------
Depth: 1
============================================================
      This is p2
------------------------------------------------------------
Depth: 2
============================================================
        This is p3
------------------------------------------------------------
Depth: 3

PL/SQL procedure successfully completed.

```




