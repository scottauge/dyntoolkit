/*
 * Removal of this header is illegal.
 * Written by Scott Auge scott_auge@yahoo.com sauge@amduus.com
 * Copyright (c) 2006 Amduus Information Works, Inc.  www.amduus.com
 * Copyright (c) 2006 Scott Auge
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by Amduus Information Works
 *      Inc. and its contributors.
 * 4. Neither the name of Amduus Information Works, Inc. nor the names of 
 *    its contributors may be used to endorse or promote products derived 
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY AMDUUS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AMDUUS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

&IF DEFINED(RCS_DYNTOOLKIT_I) = 0 &THEN
&GLOBAL-DEFINE RCS_DYNTOOLKIT_I YEP

DEF VAR RCSVersion_dyntoolkit_i AS CHARACTER INIT "$Id: dyntoolkit.i,v 1.9 2006/10/20 04:50:09 sauge Exp sauge $" NO-UNDO. 

/*****************************************************************************/
/* When the application runs against one database, it might be worth it to   */
/* set this preprocessor to NO to prevent additional code running that does  */
/* not need to run.  Leaving it as YES will not effect single DB applic-     */
/* actions - merely that it will run through some code that it doesn't need  */
/* to.  I would leave it as YES, but I know there are performance junkies out*/
/* there. See documentation for more information.                            */
/*****************************************************************************/

&GLOBAL-DEFINE USEMULTI YES

&ENDIF


/*****************************************************************************/
/* We keep a list of our dynmically created objects in this temp-table so    */
/* we can dynamically clean house.  One of the bad things though - is that   */
/* unless this table is made global - the functions only run in the scope of */
/* of this table.                                                            */
/*****************************************************************************/

DEFINE TEMP-TABLE ttDynToolKit
  FIELD QryHndl AS HANDLE     /* Use the table with multiple queries   */
  FIELD TblHndl AS HANDLE     /* How we reach the buffers of the query */
  FIELD TblName AS CHARACTER. /* For the getvalue functions.           */
  
/*****************************************************************************/
/* Use these for error reporting                                             */
/*****************************************************************************/

DEFINE VARIABLE cDyn_ErrCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDyn_ErrMsg  AS CHARACTER NO-UNDO.

/*****************************************************************************/
/* Determine the tables available in the given query.                        */
/*****************************************************************************/

FUNCTION dyn_gettables RETURNS CHARACTER (INPUT cQry AS CHARACTER):
  
  DEFINE VARIABLE iIter        AS INTEGER NO-UNDO.
  DEFINE VARIABLE iIterMax     AS INTEGER NO-UNDO.
  
  DEFINE VARIABLE cToken       AS CHARACTER NO-UNDO.
  
  DEFINE VARIABLE cTblList     AS CHARACTER INIT "" NO-UNDO.
  
  DEFINE VARIABLE iDBSeq       AS INTEGER NO-UNDO.
  DEFINE VARIABLE lIsTable     AS LOGICAL NO-UNDO.
  
  /***********************************************/ 
  /* Determine the number of tokens in our query */
  /***********************************************/
  
  ASSIGN iIterMax = NUM-ENTRIES(cQry, " ").

  /***********************************************/
  /* Check which tokens are files in the DB.     */
  /***********************************************/
  
  /**************************************************/
  /* This code runs best on multi DB apps.          */
  /* SGA: Inspired by Dayne May daynem @ linx.com.au*/  
  /**************************************************/
      
  &IF "{&USEMULTI}" = "YES" &THEN
  
  TOKEN_LOOP:
  DO iIter = 1 TO iIterMax:
  
    ASSIGN cToken = ENTRY(iIter, cQry, " ").
  
    DB_LOOP:
    DO iDBSeq = 1 TO NUM-DBS:
  
      CREATE ALIAS TEMPDB FOR DATABASE VALUE ( LDBNAME ( iDBSeq ) ).
  
      /******************************************************/
      /* Because CREATE ALIAS statement doesn't take affect */
      /* for the current compilation, split out the FIND.   */
      /******************************************************/
      
      RUN dyn_findinschema.p
        (INPUT  cToken,
         OUTPUT lIsTable).
  
  
      IF lIsTable AND NOT CAN-DO(cTblList, cToken) THEN DO:
        ASSIGN cTblList = cTblList + "," + cToken.
        NEXT TOKEN_LOOP.
      END.
                                                 
    END. /* DO iDBSeq = 1 TO NUM-DBS */
    
  END. /* DO iIter = 1 TO iIterMax */
  
  
  /***********************************************/
  /* This code runs best on single DB apps.      */
  /***********************************************/
  
  
  &ELSE
      
  DO iIter = 1 TO iIterMax:
   
    ASSIGN cToken = ENTRY(iIter, cQry, " ").
    
    IF CAN-FIND(FIRST _File WHERE _File._File-Name = cToken) THEN DO:
  
      IF NOT CAN-DO(cTblList, cToken) THEN ASSIGN cTblList = cTblList + "," + cToken.
    
    END. /* IF CAN-FIND() */
  
  END. /* DO iIter = 1 TO iIterMax */
  
  &ENDIF
  
  /***********************************************/
  /* We always end up with a closing , from      */
  /* above so prune that out.                    */
  /***********************************************/
  
  IF cTblList > "" THEN ASSIGN cTblList = SUBSTRING(cTblList, 2).
    
  RETURN cTblList.
  
END. /* FUNCTION GetTables */
  

/*****************************************************************************/
/* Open up a dynamic query and return a handle to that query.                */
/*****************************************************************************/

FUNCTION dyn_open RETURNS HANDLE (INPUT cQry AS CHARACTER):

  DEFINE VARIABLE cBufferList AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cBufferName AS CHARACTER NO-UNDO.
  
  DEFINE VARIABLE iIter       AS INTEGER NO-UNDO.
  DEFINE VARIABLE iMaxIter    AS INTEGER NO-UNDO.
  
  DEFINE VARIABLE hQryHndl    AS HANDLE NO-UNDO.
  
  DEFINE VARIABLE hTblHndl    AS HANDLE NO-UNDO.
  
  DEFINE VARIABLE lStatus     AS LOGICAL NO-UNDO.
  
  /********************************************************/
  /* Prep our error variables in case something goes bad. */
  /********************************************************/
  
  ASSIGN cDyn_ErrCode = "000"
         cDyn_ErrMsg = "No Error:" + cQry.

  /********************************************************/
  /* Create a query and do that memory stuff.             */
  /********************************************************/
  
  CREATE QUERY hQryHndl.
  
  /********************************************************/
  /* Determine buffers needed for our query.              */
  /********************************************************/
  
  ASSIGN cBufferList = dyn_gettables(cQry)
         iIter = 0.
   iMaxIter = NUM-ENTRIES(cBufferList).
   
  /* MESSAGE "cBufferList = " cBufferList. */
  
  IF cBufferList = "" THEN DO:
  
    ASSIGN cDyn_ErrCode = "102"
           cDyn_ErrMsg = "Could Not Determine Tables:" + cQry.
     
    RETURN ?.
  
  END. /* IF NOT lStatus */  

  /********************************************************/
  /* Allocate buffer space and "remember" them.           */
  /********************************************************/
  
  DO iIter = 1 TO iMaxIter:
  
    ASSIGN cBufferName = ENTRY(iIter, cBufferList).
    
    /* MESSAGE "cBufferName = " cBufferName. */
    
    CREATE BUFFER hTblHndl FOR TABLE cBufferName.
  
    CREATE ttDynToolKit.
    
    ASSIGN ttDynToolKit.QryHndl = hQryHndl
           ttDynToolKit.TblHndl = hTblHndl
     ttDynToolKit.TblName = cBufferName.
  
  END. /* FOR iIter = */
  
  /********************************************************/
  /* Lets assign our buffers to the query                 */
  /********************************************************/  
  
  FOR EACH ttDynToolKit NO-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl:
  
    hQryHndl:ADD-BUFFER(ttDynToolKit.TblHndl).
  
  END. /* FOR EACH */
  
  /********************************************************/
  /* Let's open er up.                                    */
  /********************************************************/
  
  ASSIGN lStatus = hQryHndl:QUERY-PREPARE(cQry) NO-ERROR.
  
  IF NOT lStatus THEN DO:
  
    ASSIGN cDyn_ErrCode = "100"
           cDyn_ErrMsg = "Could Not Prepare:" + cQry.
     
    RETURN ?.
  
  END. /* IF NOT lStatus */

  ASSIGN lStatus = hQryHndl:QUERY-OPEN() NO-ERROR.
  
  IF NOT lStatus THEN DO:
  
    ASSIGN cDyn_ErrCode = "101"
           cDyn_ErrMsg = "Could Not Open:" + cQry.
     
    RETURN ?.
  
  END. /* IF NOT lStatus */  
  
  /********************************************************/
  /* Return a handle to the goods.                        */
  /********************************************************/
  
  RETURN hQryHndl.
  
END. /* FUNCTION dyn_open */

/*****************************************************************************/
/* Delete all the buffers and then the query (or what ever order!)           */
/* If you do not call this - YOU WILL HAVE MEMORY LEAKS.                     */
/*****************************************************************************/

FUNCTION dyn_close RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  hQryHndl:QUERY-CLOSE().
  
  FOR EACH ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl:
    
    DELETE OBJECT ttDynToolKit.TblHndl.
    
  END. /* FOR EACH */
  
  DELETE OBJECT hQryHndl.

END. /* FUNCTION dyn_close */

/*****************************************************************************/
/* Like named wrapped around get next method.                                */
/*****************************************************************************/

FUNCTION dyn_next RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  hQryHndl:GET-NEXT.

END. /* FUNCTION dyn_next */

/*****************************************************************************/
/* Like named wrapped around get prev method.                                */
/*****************************************************************************/

FUNCTION dyn_prev RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  hQryHndl:GET-PREV.
  
END. /* FUNCTION dyn_prev */

/*****************************************************************************/
/* Slip to the end of the result set.                                        */
/*****************************************************************************/

FUNCTION dyn_last RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  hQryHndl:GET-LAST.
  
END.

/*****************************************************************************/
/* Slip to the beginning of the result set.                                  */
/*****************************************************************************/

FUNCTION dyn_first RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  hQryHndl:GET-FIRST.
  
END.

/*****************************************************************************/
/* Determine if we are at the end or before start of the query.              */
/*****************************************************************************/

FUNCTION dyn_qoe RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  RETURN hQryHndl:QUERY-OFF-END.
  
END.

/*****************************************************************************/
/* Pull a string version of the data off the field buffer.                   */
/* The TblFld is meant to be called as table.field like in usual 4GL         */
/* Right now this doesn't handle same table different DBs.                   */
/*****************************************************************************/

FUNCTION dyn_getvalue RETURNS CHARACTER (INPUT hQryHndl AS HANDLE, 
                                         INPUT cTblFld AS CHARACTER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  RETURN STRING(hFldHndl:BUFFER-VALUE).
           
END. /* FUNCTION dyn_getvalue () */

/*****************************************************************************/
/* Pull a RAW version of the data off the field buffer.                      */
/* The TblFld is meant to be called as table.field like in usual 4GL         */
/* Right now this doesn't handle same table different DBs.                   */
/*****************************************************************************/

FUNCTION dyn_getvalue_raw RETURNS RAW (INPUT hQryHndl AS HANDLE, 
                                       INPUT cTblFld AS CHARACTER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  RETURN hFldHndl:BUFFER-VALUE.
           
END. /* FUNCTION dyn_getvalue_raw () */

/*****************************************************************************/
/* Pull a ROWID of the record off the field buffer.                   */
/* The TblFld is meant to be called as table.field like in usual 4GL         */
/* Right now this doesn't handle same table different DBs.                   */
/*****************************************************************************/

FUNCTION dyn_getvalue_rowid RETURNS ROWID (INPUT hQryHndl AS HANDLE, 
                                           INPUT cTblName AS CHARACTER):

  DEFINE VARIABLE hTblHndl AS HANDLE NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = cTblName.
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  hTblHndl = ttDynToolKit.TblHndl.

  RETURN hTblHndl:ROWID.
           
END. /* FUNCTION dyn_getvalue_rowid () */

/*****************************************************************************/
/* Pull a RECID of the record off the field buffer.                   */
/* The TblFld is meant to be called as table.field like in usual 4GL         */
/* Right now this doesn't handle same table different DBs.                   */
/*****************************************************************************/

FUNCTION dyn_getvalue_recid RETURNS RECID (INPUT hQryHndl AS HANDLE, 
                                           INPUT cTblName AS CHARACTER):

  DEFINE VARIABLE hTblHndl AS HANDLE NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = cTblName.
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  hTblHndl = ttDynToolKit.TblHndl.

  RETURN hTblHndl:RECID.
           
END. /* FUNCTION dyn_getvalue_recid () */

/*****************************************************************************/
/* Given a table.field, determine the field type.                            */
/* The TblFld is meant to be called as table.field like in usual 4GL         */
/* Right now this doesn't handle same table different DBs.                   */
/*****************************************************************************/

FUNCTION dyn_fieldtype RETURNS CHARACTER (INPUT hQryHndl AS HANDLE, 
                                          INPUT cTblFld AS CHARACTER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  RETURN hFldHndl:DATA-TYPE.
           
END. /* FUNCTION dyn_fieldtype () */

/*****************************************************************************/
/* Given a table.field, determine the field type.                            */
/* The TblFld is meant to be called as table.field like in usual 4GL         */
/* Right now this doesn't handle same table different DBs.                   */
/* WARNING: THIS IS NOT TESTED.                                              */
/*****************************************************************************/

FUNCTION dyn_fieldhdl RETURNS HANDLE (INPUT hQryHndl AS HANDLE, 
                                      INPUT cTblFld AS CHARACTER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  RETURN hFldHndl.
           
END. /* FUNCTION dyn_fieldhdl () */

/*****************************************************************************/
/* Given a query and table name, return the buffer table for the table.      */
/*****************************************************************************/ 

FUNCTION dyn_tablehdl RETURNS HANDLE (INPUT hQryHndl AS HANDLE, 
                                     INPUT cTableName AS CHARACTER):

  FIND ttDynToolKit NO-LOCK
  WHERE ttDynToolkit.QryHndl = hQryHndl
  AND ttDynToolkit.TblName = cTableName
  NO-ERROR.
  
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  RETURN ttDynToolKit.TblHndl.
                                   
END. /* FUNCTION dyn_tblhndl */

/*****************************************************************************/
/* Provide a means of returning the number of results in a query.            */
/* Running this on 9.1C and getting zero even though there is a result set   */
/* greater than zero.                                                        */
/*****************************************************************************/

FUNCTION dyn_numresults RETURNS INTEGER (INPUT hQryHndl AS HANDLE):

  DEFINE VARIABLE iNum AS INTEGER NO-UNDO.
  
  ASSIGN iNum =  hQryHndl:NUM-RESULTS.
  
  RETURN iNum.
  
END. /* FUNCTION dyn_numresults */

/*****************************************************************************/
/* Given a query handle, build up the ttDynToolKit table from it.  Useful    */
/* for when a query handle is passed into an external procedure and one      */
/* wants to use the tool kit's functions.                                    */
/*****************************************************************************/

FUNCTION dyn_qryinfo RETURNS LOGICAL (INPUT hQryHndl AS HANDLE):

  DEFINE VARIABLE iCurBufSeq AS INTEGER NO-UNDO.

  /****************************************************/
  /* Clean up the ttDynToolKit table of this query so */.
  /* we don't get duplicates.                         */
  /****************************************************/

  FOR EACH ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl:
  
    DELETE ttDynToolKit.
    
  END.

  /****************************************************/
  /* Rebuild the table from the info available in the */
  /* dynamic objects.                                 */
  /****************************************************/
  
  DO iCurBufSeq = 1 TO hQryHndl:NUM-BUFFERS:
  
    CREATE ttDynToolKit.
    
    ASSIGN ttDynToolkit.QryHndl = hQryHndl
           ttDynToolKit.TblHndl = hQryHndl:GET-BUFFER-HANDLE(iCurBufSeq)
           ttDynToolKit.TblName = ttDynToolKit.TblHndl:TABLE.
     
  END. /* DO iCurBufSeq = 1 TO hQryHndl:NUM-BUFFERS */
  
END. /* FUNCTION dyn_qryinfo () */

/*****************************************************************************/
/* Simple dump routine for the table.                                        */
/*****************************************************************************/

FUNCTION dyn_dump RETURNS LOGICAL (INPUT cFileName AS CHARACTER):

  OUTPUT TO VALUE (cFileName).
  
  FOR EACH ttDynToolKit EXCLUSIVE-LOCK:
 
    EXPORT INT(ttDynToolkit.QryHndl)  INT(ttDynToolKit.TblHndl)   ttDynToolKit.TblName.
    
  END. /* FOR EACH ttDynToolKit */
    
  OUTPUT CLOSE.
  
END.

/*****************************************************************************/
/* Given a table name, determine the number of fields on it.                 */
/*****************************************************************************/ 

FUNCTION dyn_numfields RETURNS INTEGER (INPUT hQryHndl AS HANDLE, 
                                        INPUT cTableName AS CHARACTER):

  FIND ttDynToolKit NO-LOCK
  WHERE ttDynToolkit.QryHndl = hQryHndl
    AND ttDynToolkit.TblName = cTableName
    
  NO-ERROR.
  
  IF NOT AVAILABLE ttDynToolKit THEN RETURN ?.
  
  RETURN ttDynToolKit.TblHndl:NUM-FIELDS.
                                   
END. /* FUNCTION dyn_numfields */
      
/*****************************************************************************/
/* Given a query handle, how many tables are in the query  .                 */
/*****************************************************************************/ 
                       
FUNCTION dyn_numtables RETURNS INTEGER (INPUT hQryHndl AS HANDLE):

  DEFINE VARIABLE iCnt AS INTEGER INIT 0 NO-UNDO.
  
  FOR EACH ttDynToolKit NO-LOCK
  WHERE ttDynToolkit.QryHndl = hQryHndl:
  
    ASSIGN iCnt = iCnt + 1.
    
  END.
  
  RETURN iCnt.
  
END. /* FUNCTION dyn_numtables () */

/*****************************************************************************/
/* Given a query handle, what are the table names          .                 */
/*****************************************************************************/ 
                       
FUNCTION dyn_listtables RETURNS CHARACTER (INPUT hQryHndl AS HANDLE):

  DEFINE VARIABLE cList AS CHARACTER INIT "" NO-UNDO.
  
  FOR EACH ttDynToolKit NO-LOCK
  WHERE ttDynToolkit.QryHndl = hQryHndl:
  
    ASSIGN cList = cList + ttDynToolKit.TblName + ",".
    
  END.
  
  ASSIGN cList = SUBSTRING(cList, 1, LENGTH(cList) - 1).
  
  RETURN cList.
  
END. /* FUNCTION dyn_numtables () */
/*****************************************************************************/
/* Given a query handle, what are the table names          .                 */
/*****************************************************************************/ 
                       
FUNCTION dyn_listfields RETURNS CHARACTER (INPUT hQryHndl AS HANDLE, 
                                           INPUT cTableName AS CHARACTER):

  DEFINE VARIABLE iCntFields AS INTEGER NO-UNDO.
  DEFINE VARIABLE iCurField  AS INTEGER NO-UNDO.
  DEFINE VARIABLE cList AS CHARACTER INIT "" NO-UNDO.
  DEFINE VARIABLE hField AS HANDLE NO-UNDO.
  
  ASSIGN iCntFields = dyn_numfields (hQryHndl, cTableName).
  IF iCntFields = ? THEN RETURN ?.
  
  FIND ttDynToolKit NO-LOCK
  WHERE ttDynToolkit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = cTableName.
    
    
  DO iCurField = 1 TO iCntFields:
  
    ASSIGN hField = ttDynToolKit.TblHndl:BUFFER-FIELD(iCurField).
    
    ASSIGN cList = cList + hField:Name + ",".
    
  END.
  
  ASSIGN cList = SUBSTRING(cList, 1, LENGTH(cList) - 1).
  
  RETURN cList.
  
END. /* FUNCTION dyn_numtables () */

/*****************************************************************************/
/*****************************************************************************/
/*                                PLEASE READ                                */
/*                                  ______                                   */
/*                               .-"      "-.                                */
/*                              /            \                               */
/*                  _          |              |          _                   */
/*                 ( \         |,  .-.  .-.  ,|         / )                  */
/*                  > "=._     | )(__/  \__)( |     _.=" <                   */
/*                 (_/"=._"=._ |/     /\     \| _.="_.="\_)                  */
/*                        "=._ (_     ^^     _)"_.="                         */
/*                            "=\__|IIIIII|__/="                             */
/*                           _.="| \IIIIII/ |"=._                            */
/*                 _     _.="_.="\          /"=._"=._     _                  */
/*                ( \_.="_.="     `--------`     "=._"=._/ )                 */
/*                 > _.="  DO NOT EDIT FRIVOLOUSLY!  "=._ <                  */
/*                (_/                                    \_)                 */
/*                                                                           */
/* WARNING: ASSIGNING A FIELD USED TO ORDER THE QUERY WILL HOSE THE QUERY.   */
/*                                                                           */
/*****************************************************************************/
/*****************************************************************************/




/*****************************************************************************/
/* Progress has no LOGICAL function.  Here we set up a way to translate CHAR */
/* representations of logicals to a actual progress data type of LOGICAL.    */
/*****************************************************************************/

FUNCTION SET_LOGICAL RETURNS LOGICAL (INPUT cText AS CHARACTER):

  IF cText = ? THEN RETURN ?.
  
  IF CAN-DO("Y,YES,TRUE", cText) THEN RETURN TRUE.
  
  RETURN FALSE.
  
END. /* FUNCTION SET_LOGICAL */

/*****************************************************************************/
/* Allow the setting of any type values via a string source.  No error       */
/* checking - assume the programmer has a clue.                              */
/*****************************************************************************/

FUNCTION dyn_set RETURNS LOGICAL (INPUT hQryHndl AS HANDLE, 
                                  INPUT cTblFld AS CHARACTER, 
          INPUT cText AS CHARACTER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN FALSE.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  CASE hFldHndl:DATA-TYPE:
  
    WHEN "CHARACTER" THEN ASSIGN hFldHndl:BUFFER-VALUE = cText.

    WHEN "LOGICAL" THEN ASSIGN hFldHndl:BUFFER-VALUE = SET_LOGICAL(cText).

    WHEN "DATE" THEN ASSIGN hFldHndl:BUFFER-VALUE = DATE(cText).

    WHEN "INTEGER" THEN ASSIGN hFldHndl:BUFFER-VALUE = INTEGER(cText).

    WHEN "DECIMAL" THEN ASSIGN hFldHndl:BUFFER-VALUE = DECIMAL(cText).
    
  END. /* CASE */    
  
  RETURN TRUE.
  
END. /* FUNCTION dyn_setc() */

/*****************************************************************************/
/* Allow the setting of character type values.  No error checking - assume   */
/* the programmer has a clue.                                                */
/*****************************************************************************/

FUNCTION dyn_setc RETURNS LOGICAL (INPUT hQryHndl AS HANDLE, 
                                   INPUT cTblFld AS CHARACTER, 
           INPUT cText AS CHARACTER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN FALSE.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  ASSIGN hFldHndl:BUFFER-VALUE = cText.
  
  RETURN TRUE.
  
END. /* FUNCTION dyn_setc() */

/*****************************************************************************/
/* Allow the setting of character type values.  No error checking - assume   */
/* the programmer has a clue.                                                */
/*****************************************************************************/

FUNCTION dyn_seti RETURNS LOGICAL (INPUT hQryHndl AS HANDLE, 
                                   INPUT cTblFld AS CHARACTER, 
           INPUT iVal AS INTEGER):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN FALSE.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  ASSIGN hFldHndl:BUFFER-VALUE = iVal.
  
  RETURN TRUE.
  
END. /* FUNCTION dyn_setc() */

/*****************************************************************************/
/* Allow the setting of character type values.  No error checking - assume   */
/* the programmer has a clue.                                                */
/*****************************************************************************/

FUNCTION dyn_setf RETURNS LOGICAL (INPUT hQryHndl AS HANDLE, 
                                   INPUT cTblFld AS CHARACTER, 
           INPUT fVal AS DECIMAL):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN FALSE.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  ASSIGN hFldHndl:BUFFER-VALUE = fVal.
  
  RETURN TRUE.
  
END. /* FUNCTION dyn_setc() */

/*****************************************************************************/
/* Allow the setting of character type values.  No error checking - assume   */
/* the programmer has a clue.                                                */
/*****************************************************************************/

FUNCTION dyn_setl RETURNS LOGICAL (INPUT hQryHndl AS HANDLE, 
                                   INPUT cTblFld AS CHARACTER, 
           INPUT lVal AS LOGICAL):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN FALSE.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  ASSIGN hFldHndl:BUFFER-VALUE = lVal.
  
  RETURN TRUE.
  
END. /* FUNCTION dyn_setc() */

/*****************************************************************************/
/* Allow the setting of character type values.  No error checking - assume   */
/* the programmer has a clue.                                                */
/*****************************************************************************/

FUNCTION dyn_setd RETURNS LOGICAL (INPUT hQryHndl AS HANDLE, 
                                   INPUT cTblFld AS CHARACTER, 
           INPUT dVal AS DATE):

  DEFINE VARIABLE hFldHndl AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  
  FIND ttDynToolKit EXCLUSIVE-LOCK
  WHERE ttDynToolKit.QryHndl = hQryHndl
    AND ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
    
  IF NOT AVAILABLE ttDynToolKit THEN RETURN FALSE.
  
  ASSIGN hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(ENTRY(2, cTblFld, ".")).
 
  ASSIGN hFldHndl:BUFFER-VALUE = dVal.
  
  RETURN TRUE.
  
END. /* FUNCTION dyn_setc() */

