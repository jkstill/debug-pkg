PL/SQL Debugging Routines
=========================

Just some things to help with debugging

## call_stack package

It would be useful to know what the current level is in the call stack when debugging.

For Oracle 12c+, that can be obtained via UTL_CALL_STACK.DYNAMIC_DEPTH.

For older versions, it is more difficult.

What this code does is walk through the call stack and look for address lines.

The call depth is 0 based. 

When you build the call_stack package, dbms_db_version.version is used to determine which code to compile.

This has been tested on 11.1 and 19.8 versions of the oracle database.


### demo-02.sql

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


