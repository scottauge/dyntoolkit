/***************************************************************************/
/* ONLY CALL THIS PROGRAM FROM dyntoolkit.i WHICH CREATES THE ALIAS        */
/* TEMPDB.                                                                 */
/* SGA: Donated by Dayne May daynem @ linx.com.au                          */
/* How to compile this.                                                    */
/*    Connect to a DB with -ld tempdb  (Any DB should do)                  */
/*    Compile and save r-code                                              */
/***************************************************************************/

DEFINE VARIABLE RCS AS CHARACTER INIT "$Id: dyn_findinschema.p,v 1.3 2006/10/20 05:01:44 sauge Exp sauge $" NO-UNDO.

DEFINE INPUT  PARAMETER pcTable AS CHARACTER.
DEFINE OUTPUT PARAMETER plOK AS LOGICAL.

FIND FIRST tempdb._file 
    WHERE tempdb._file._file-name = pcTable
    NO-LOCK NO-ERROR.

ASSIGN plOK = AVAILABLE tempdb._file.
