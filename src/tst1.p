
/* Testing of new functions in dyntoolkit.i - performed in webspeed scripting lab */

{dyntoolkit.i}

DEFINE VARIABLE h AS HANDLE NO-UNDO.

ASSIGN h = dyn_open("for each users no-lock, each userentity where userloginid = users.userloginid").

{&OUT} "Number of results: " dyn_numresults(h) "<br>" SKIP.

{&OUT} "Number of tables: " dyn_numtables(h) "<br>" SKIP.

{&OUT} "List of tables: " dyn_listtables(h) "<br>" SKIP.


{&OUT} "List of fields in users: " dyn_listfields(h, "users") "<br>" SKIP.

dyn_next(h).


{&OUT} "Value of users.userloginid: " dyn_getvalue(h, "users.userloginid") "<br>".

dyn_close(h).
