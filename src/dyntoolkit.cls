 
 /*------------------------------------------------------------------------
    File        : dyntoolkit
    Purpose     : 
    Syntax      : 
    Description : Class for dynamic queries
    Author(s)   : scott
    Created     : Mon Feb 01 13:31:47 EST 2021
    Notes       : 
  ----------------------------------------------------------------------*/
  
  
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
 
   

using Progress.Lang.*.

block-level on error undo, throw.

class dyntoolkit: 

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  constructor public dyntoolkit ( input cQry as character ):
    
    super ().
    dyn_open(cQry).
    
  end constructor.
  
  constructor public dyntoolkit ( ):
    
    super ().
    
  end constructor.  

  destructor public dyntoolkit ( ):

    dyn_close ().
    
  end destructor.
  
  
  


  &IF DEFINED(RCS_DYNTOOLKIT_I) = 0 &THEN
  &GLOBAL-DEFINE RCS_DYNTOOLKIT_I YEP
  
  def var RCSVersion_dyntoolkit_i as character init "$Id: dyntoolkit.i,v 1.9 2006/10/20 04:50:09 sauge Exp sauge $" no-undo. 
  
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
  /* unless this table is made global - the method publics only run in the scope of */
  /* of this table.                                                            */
  /*****************************************************************************/
  
  define temp-table ttDynToolKit
    field QryHndl as handle     /* Use the table with multiple queries   */
    field TblHndl as handle     /* How we reach the buffers of the query */
    field TblName as character. /* For the getvalue functions.           */
    
  /*****************************************************************************/
  /* Use these for error reporting                                             */
  /*****************************************************************************/
  
  define public variable cDyn_ErrCode as character no-undo.
  define public variable cDyn_ErrMsg  as character no-undo.
  
  /*****************************************************************************/
  /* Make this internal to the class                                           */
  /*****************************************************************************/
  
  define variable hQryHndl    as handle no-undo.
   
  /*****************************************************************************/
  /* Determine the tables available in the given query.                        */
  /*****************************************************************************/
  
  method public character dyn_gettables (input cQry as character):
    
    define variable iIter        as integer no-undo.
    define variable iIterMax     as integer no-undo.
    
    define variable cToken       as character no-undo.
    
    define variable cTblList     as character init "" no-undo.
    
    define variable iDBSeq       as integer no-undo.
    define variable lIsTable     as logical no-undo.
    
    /***********************************************/ 
    /* Determine the number of tokens in our query */
    /***********************************************/
    
    assign iIterMax = num-entries(cQry, " ").
  
    /***********************************************/
    /* Check which tokens are files in the DB.     */
    /***********************************************/
    
    /**************************************************/
    /* This code runs best on multi DB apps.          */
    /* SGA: Inspired by Dayne May daynem @ linx.com.au*/  
    /**************************************************/
        
    &IF "{&USEMULTI}" = "YES" &THEN
    
    TOKEN_LOOP:
    do iIter = 1 to iIterMax:
    
      assign cToken = entry(iIter, cQry, " ").
    
      DB_LOOP:
      do iDBSeq = 1 to num-dbs:
    
        create alias TEMPDB for database value ( ldbname ( iDBSeq ) ).
    
        /******************************************************/
        /* Because CREATE ALIAS statement doesn't take affect */
        /* for the current compilation, split out the FIND.   */
        /******************************************************/
        
        run dyn_findinschema.p
          (input  cToken,
           output lIsTable).
    
    
        if lIsTable and not CAN-DO(cTblList, cToken) then do:
          assign cTblList = cTblList + "," + cToken.
          next TOKEN_LOOP.
        end.
                                                   
      end. /* DO iDBSeq = 1 TO NUM-DBS */
      
    end. /* DO iIter = 1 TO iIterMax */
    
    
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
    
    if cTblList > "" then assign cTblList = substring(cTblList, 2).
      
    return cTblList.
    
  end. /* method public GetTables */
    
  
  /*****************************************************************************/
  /* Open up a dynamic query and return a handle to that query.                */
  /* Call this after the empty arg constructor to get the handle back.         */
  /*****************************************************************************/
  
  method public handle dyn_open (input cQry as character):
  
    define variable cBufferList as character no-undo.
    define variable cBufferName as character no-undo.
    
    define variable iIter       as integer no-undo.
    define variable iMaxIter    as integer no-undo.
    
   
    
    define variable hTblHndl    as handle no-undo.
    
    define variable lStatus     as logical no-undo.
    
    /********************************************************/
    /* Prep our error variables in case something goes bad. */
    /********************************************************/
    
    assign cDyn_ErrCode = "000"
           cDyn_ErrMsg = "No Error:" + cQry.
  
    /********************************************************/
    /* Create a query and do that memory stuff.             */
    /********************************************************/
    
    create query hQryHndl.
    
    /********************************************************/
    /* Determine buffers needed for our query.              */
    /********************************************************/
    
    assign cBufferList = dyn_gettables(cQry)
           iIter = 0.
     iMaxIter = num-entries(cBufferList).
     
    /* MESSAGE "cBufferList = " cBufferList. */
    
    if cBufferList = "" then do:
    
      assign cDyn_ErrCode = "102"
             cDyn_ErrMsg = "Could Not Determine Tables:" + cQry.
       
      return ?.
    
    end. /* IF NOT lStatus */  
  
    /********************************************************/
    /* Allocate buffer space and "remember" them.           */
    /********************************************************/
    
    do iIter = 1 to iMaxIter:
    
      assign cBufferName = entry(iIter, cBufferList).
      
      /* MESSAGE "cBufferName = " cBufferName. */
      
      create buffer hTblHndl for table cBufferName.
    
      create ttDynToolKit.
      
      assign ttDynToolKit.QryHndl = hQryHndl
             ttDynToolKit.TblHndl = hTblHndl
       ttDynToolKit.TblName = cBufferName.
    
    end. /* FOR iIter = */
    
    /********************************************************/
    /* Lets assign our buffers to the query                 */
    /********************************************************/  
    
    for each ttDynToolKit no-lock
    where ttDynToolKit.QryHndl = hQryHndl:
    
      hQryHndl:add-buffer(ttDynToolKit.TblHndl).
    
    end. /* FOR EACH */
    
    /********************************************************/
    /* Let's open er up.                                    */
    /********************************************************/
    
    assign lStatus = hQryHndl:query-prepare(cQry) NO-ERROR.
    
    if not lStatus then do:
    
      assign cDyn_ErrCode = "100"
             cDyn_ErrMsg = "Could Not Prepare:" + cQry.
       
      return ?.
    
    end. /* IF NOT lStatus */
  
    assign lStatus = hQryHndl:query-open() NO-ERROR.
    
    if not lStatus then do:
    
      assign cDyn_ErrCode = "101"
             cDyn_ErrMsg = "Could Not Open:" + cQry.
       
      return ?.
    
    end. /* IF NOT lStatus */  
    
    /*************************************************************************/
    /* Return a handle to the goods.    Can be returned but does need to     */
    /*************************************************************************/
    
    return hQryHndl.
    
  end. /* method public dyn_open */
  
  /*****************************************************************************/
  /* Delete all the buffers and then the query (or what ever order!)           */
  /* If you do not call this - YOU WILL HAVE MEMORY LEAKS.                     */
  /*****************************************************************************/
  
  method public logical dyn_close ():
    
    return dyn_close(hQryHndl).
    
  end. 
  
  method public logical dyn_close (input hQryHndl as handle):
  
    hQryHndl:query-close().
    
    for each ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl:
      
      delete object ttDynToolKit.TblHndl.
      
    end. /* FOR EACH */
    
    delete object hQryHndl.
  
  end. /* method public dyn_close */
  
  /*****************************************************************************/
  /* Like named wrapped around get next method.                                */
  /*****************************************************************************/
  
  method public logical dyn_next ():
    
    dyn_next(hQryHndl).
    
  end.
  
  method public logical dyn_next (input hQryHndl as handle):
  
    hQryHndl:get-next.
  
  end. /* method public dyn_next */
  
  /*****************************************************************************/
  /* Like named wrapped around get prev method.                                */
  /*****************************************************************************/
  
  method public logical dyn_prev():
    
    dyn_prev (hQryHndl).
    
  end.
  
  method public logical dyn_prev  (input hQryHndl as handle):
  
    hQryHndl:get-prev.
    
  end. /* method public dyn_prev */
  
  /*****************************************************************************/
  /* Slip to the end of the result set.                                        */
  /*****************************************************************************/
  
  method public logical dyn_last():
    
    dyn_last(hQryHndl).
    
  end.
  
  method public logical dyn_last   (input hQryHndl as handle):
  
    hQryHndl:get-last.
    
  end.
  
  /*****************************************************************************/
  /* Slip to the beginning of the result set.                                  */
  /*****************************************************************************/
  
  method public logical dyn_first():
    
    dyn_first(hQryHndl).
    
  end.
  
  method public logical dyn_first   (input hQryHndl as handle):
  
    hQryHndl:get-first.
    
  end.
  
  /*****************************************************************************/
  /* Determine if we are at the end or before start of the query.              */
  /*****************************************************************************/
  
  method public logical dyn_qoe():
    
    return dyn_qoe(hQryHndl).
    
  end.
  
  method public logical dyn_qoe   (input hQryHndl as handle):
  
    return hQryHndl:query-off-end.
    
  end.
  
  /*****************************************************************************/
  /* Pull a string version of the data off the field buffer.                   */
  /* The TblFld is meant to be called as table.field like in usual 4GL         */
  /* Right now this doesn't handle same table different DBs.                   */
  /*****************************************************************************/
  
  method public character dyn_getvalue (input cTblFld as character):
  
    return dyn_getvalue(hQryHndl, cTblFld).
    
  end.
  
  method public character dyn_getvalue   (input hQryHndl as handle, 
                                           input cTblFld as character):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return ?.
    
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    return string(hFldHndl:buffer-value).
             
  end. /* method public dyn_getvalue () */
  
  /*****************************************************************************/
  /* Pull a RAW version of the data off the field buffer.                      */
  /* The TblFld is meant to be called as table.field like in usual 4GL         */
  /* Right now this doesn't handle same table different DBs.                   */
  /*****************************************************************************/
  
  method public raw dyn_getvalue_raw (input cTblFld as character):
  
    return dyn_getvalue_raw(hQryHndl, cTblFld).
    
  end.
  
  method public raw dyn_getvalue_raw  (input hQryHndl as handle, 
                                         input cTblFld as character):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return ?.
    
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    return hFldHndl:buffer-value.
             
  end. /* method public dyn_getvalue_raw () */
  
  /*****************************************************************************/
  /* Pull a ROWID of the record off the field buffer.                   */
  /* The TblFld is meant to be called as table.field like in usual 4GL         */
  /* Right now this doesn't handle same table different DBs.                   */
  /*****************************************************************************/
  
  method public rowid dyn_getvalue_rowid (input cTblName as character):
  
    return dyn_getvalue_rowid(hQryHndl, cTblName).
    
  end.
  
  
  method public rowid dyn_getvalue_rowid   (input hQryHndl as handle, 
                                             input cTblName as character):
  
    define variable hTblHndl as handle no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = cTblName.
      
    if not available ttDynToolKit then return ?.
    
    hTblHndl = ttDynToolKit.TblHndl.
  
    return hTblHndl:rowid.
             
  end. /* method public dyn_getvalue_rowid () */
  
  /*****************************************************************************/
  /* Pull a RECID of the record off the field buffer.                   */
  /* The TblFld is meant to be called as table.field like in usual 4GL         */
  /* Right now this doesn't handle same table different DBs.                   */
  /*****************************************************************************/
  
  method public recid dyn_getvalue_recid (input cTblName as character):
  
    return dyn_getvalue_recid(hQryHndl, cTblName).
    
  end.
  
  
  method public recid dyn_getvalue_recid   (input hQryHndl as handle, 
                                             input cTblName as character):
  
    define variable hTblHndl as handle no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = cTblName.
      
    if not available ttDynToolKit then return ?.
    
    hTblHndl = ttDynToolKit.TblHndl.
  
    return hTblHndl:recid.
             
  end. /* method public dyn_getvalue_recid () */
  
  /*****************************************************************************/
  /* Given a table.field, determine the field type.                            */
  /* The TblFld is meant to be called as table.field like in usual 4GL         */
  /* Right now this doesn't handle same table different DBs.                   */
  /*****************************************************************************/
  
  
  method public character dyn_fieldtype (input cTblFld as character):
  
    return dyn_fieldtype (hQryHndl, cTblFld).
    
  end.
  
  
  method public character dyn_fieldtype   (input hQryHndl as handle, 
                                            input cTblFld as character):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return ?.
    
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    return hFldHndl:data-type.
             
  end. /* method public dyn_fieldtype () */
  
  /*****************************************************************************/
  /* Given a table.field, determine the field type.                            */
  /* The TblFld is meant to be called as table.field like in usual 4GL         */
  /* Right now this doesn't handle same table different DBs.                   */
  /* WARNING: THIS IS NOT TESTED.                                              */
  /*****************************************************************************/
  
  method public handle dyn_fieldhdl (input cTblFld as character):
  
    return dyn_fieldhdl (hQryHndl, cTblFld).
    
  end.
  
  method public handle dyn_fieldhdl   (input hQryHndl as handle, 
                                        input cTblFld as character):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return ?.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    return hFldHndl.
             
  end. /* method public dyn_fieldhdl () */
  
  /*****************************************************************************/
  /* Given a query and table name, return the buffer table for the table.      */
  /*****************************************************************************/ 
  
  method public handle dyn_tablehdl (input cTableName as character):
  
    return dyn_tablehdl (hQryHndl, cTableName).
    
  end.
  
  
  method public handle dyn_tablehdl   (input hQryHndl as handle, 
                                       input cTableName as character):
  
    find ttDynToolKit no-lock
    where ttDynToolkit.QryHndl = hQryHndl
    and ttDynToolkit.TblName = cTableName
    no-error.
    
    if not available ttDynToolKit then return ?.
    
    return ttDynToolKit.TblHndl.
                                     
  end. /* method public dyn_tblhndl */
  
  /*****************************************************************************/
  /* Provide a means of returning the number of results in a query.            */
  /* Running this on 9.1C and getting zero even though there is a result set   */
  /* greater than zero.                                                        */
  /*****************************************************************************/
  
  method public integer dyn_numresults ():
  
    return dyn_numresults (hQryHndl).
    
  end.
  
  method public integer dyn_numresults   (input hQryHndl as handle):
  
    define variable iNum as integer no-undo.
    
    assign iNum =  hQryHndl:num-results.
    
    return iNum.
    
  end. /* method public dyn_numresults */
  
  /*****************************************************************************/
  /* Given a query handle, build up the ttDynToolKit table from it.  Useful    */
  /* for when a query handle is passed into an external procedure and one      */
  /* wants to use the tool kit's functions.                                    */
  /*****************************************************************************/
  
  method public logical dyn_qryinfo ():
  
    return dyn_qryinfo (hQryHndl).
    
  end.
  
  
  method public logical dyn_qryinfo   (input hQryHndl as handle):
  
    define variable iCurBufSeq as integer no-undo.
  
    /****************************************************/
    /* Clean up the ttDynToolKit table of this query so */.
    /* we don't get duplicates.                         */
    /****************************************************/
  
    for each ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl:
    
      delete ttDynToolKit.
      
    end.
  
    /****************************************************/
    /* Rebuild the table from the info available in the */
    /* dynamic objects.                                 */
    /****************************************************/
    
    do iCurBufSeq = 1 to hQryHndl:num-buffers:
    
      create ttDynToolKit.
      
      assign ttDynToolkit.QryHndl = hQryHndl
             ttDynToolKit.TblHndl = hQryHndl:get-buffer-handle(iCurBufSeq)
             ttDynToolKit.TblName = ttDynToolKit.TblHndl:TABLE.
       
    end. /* DO iCurBufSeq = 1 TO hQryHndl:NUM-BUFFERS */
    
  end. /* method public dyn_qryinfo () */
  
  /*****************************************************************************/
  /* Simple dump routine for the table.                                        */
  /*****************************************************************************/
  
  method public logical dyn_dump   (input cFileName as character):
  
    output TO VALUE (cFileName).
    
    for each ttDynToolKit exclusive-lock:
   
      export INT(ttDynToolkit.QryHndl)  INT(ttDynToolKit.TblHndl)   ttDynToolKit.TblName.
      
    end. /* FOR EACH ttDynToolKit */
      
    output CLOSE.
    
  end.
  
  /*****************************************************************************/
  /* Given a table name, determine the number of fields on it.                 */
  /*****************************************************************************/ 
  
  method public integer dyn_numfields (input cTableName as character):
  
    return dyn_numfields (hQryHndl, cTableName).
  
  end.
  
  method public integer dyn_numfields   (input hQryHndl as handle, 
                                          input cTableName as character):
  
    find ttDynToolKit no-lock
    where ttDynToolkit.QryHndl = hQryHndl
      and ttDynToolkit.TblName = cTableName
      
    no-error.
    
    if not available ttDynToolKit then return ?.
    
    return ttDynToolKit.TblHndl:NUM-FIELDS.
                                     
  end. /* method public dyn_numfields */
        
  /*****************************************************************************/
  /* Given a query handle, how many tables are in the query  .                 */
  /*****************************************************************************/ 
                         
  method public integer dyn_numtables ():
  
    return dyn_numtables(hQryHndl).
    
  end.
                           
  method public integer dyn_numtables   (input hQryHndl as handle):
  
    define variable iCnt as integer init 0 no-undo.
    
    for each ttDynToolKit no-lock
    where ttDynToolkit.QryHndl = hQryHndl:
    
      assign iCnt = iCnt + 1.
      
    end.
    
    return iCnt.
    
  end. /* method public dyn_numtables () */
  
  /*****************************************************************************/
  /* Given a query handle, what are the table names          .                 */
  /*****************************************************************************/ 
                         
  method public character dyn_listtables ():
    
    return dyn_listtables (hQryHndl).
    
  end. 
  
                           
  method public character dyn_listtables   (input hQryHndl as handle):
  
    define variable cList as character init "" no-undo.
    
    for each ttDynToolKit no-lock
    where ttDynToolkit.QryHndl = hQryHndl:
    
      assign cList = cList + ttDynToolKit.TblName + ",".
      
    end.
    
    assign cList = substring(cList, 1, length(cList) - 1).
    
    return cList.
    
  end. /* method public dyn_numtables () */
  /*****************************************************************************/
  /* Given a query handle, what are the table names          .                 */
  /*****************************************************************************/ 
      
  method public character dyn_listfields (input cTableName as character):
    
    return dyn_listfields(hQryHndl, cTableName).
    
  end.
                     
  method public character dyn_listfields   (input hQryHndl as handle, 
                                             input cTableName as character):
  
    define variable iCntFields as integer no-undo.
    define variable iCurField  as integer no-undo.
    define variable cList as character init "" no-undo.
    define variable hField as handle no-undo.
    
    assign iCntFields = dyn_numfields (hQryHndl, cTableName).
    if iCntFields = ? then return ?.
    
    find ttDynToolKit no-lock
    where ttDynToolkit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = cTableName.
      
      
    do iCurField = 1 to iCntFields:
    
      assign hField = ttDynToolKit.TblHndl:BUFFER-FIELD(iCurField).
      
      assign cList = cList + hField:name + ",".
      
    end.
    
    assign cList = substring(cList, 1, length(cList) - 1).
    
    return cList.
    
  end. /* method public dyn_numtables () */
  
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
  
  method public logical SET_LOGICAL   (input cText as character):
  
    if cText = ? then return ?.
    
    if can-do("Y,YES,TRUE", cText) then return true.
    
    return false.
    
  end. /* method public SET_LOGICAL */
  
  /*****************************************************************************/
  /* Allow the setting of any type values via a string source.  No error       */
  /* checking - assume the programmer has a clue.                              */
  /*****************************************************************************/
  
  method public logical dyn_set (input cTblFld as character, input cText as character):
    
    return dyn_set(hQryHndl, cTblFld, cText).
    
  end.
  
  
  method public logical dyn_set   (input hQryHndl as handle, 
                                    input cTblFld as character, 
            input cText as character):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return false.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    case hFldHndl:data-type:
    
      when "CHARACTER" then assign hFldHndl:buffer-value = cText.
  
      when "LOGICAL" then assign hFldHndl:buffer-value = SET_LOGICAL(cText).
  
      when "DATE" then assign hFldHndl:buffer-value = date(cText).
  
      when "INTEGER" then assign hFldHndl:buffer-value = integer(cText).
  
      when "DECIMAL" then assign hFldHndl:buffer-value = decimal(cText).
      
    end. /* CASE */    
    
    return true.
    
  end. /* method public dyn_setc() */
  
  /*****************************************************************************/
  /* Allow the setting of character type values.  No error checking - assume   */
  /* the programmer has a clue.                                                */
  /*****************************************************************************/
  
  method public logical dyn_setc (input cTblFld as character, 
             input cText as character):
  
    return dyn_setc (hQryHndl, cTblFld, cText).
    
  end.
  
  
  method public logical dyn_setc   (input hQryHndl as handle, 
                                     input cTblFld as character, 
             input cText as character):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return false.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    assign hFldHndl:buffer-value = cText.
    
    return true.
    
  end. /* method public dyn_setc() */
  
  /*****************************************************************************/
  /* Allow the setting of character type values.  No error checking - assume   */
  /* the programmer has a clue.                                                */
  /*****************************************************************************/
  
  method public logical dyn_seti (input cTblFld as character, 
             input iVal as integer):
  
    return dyn_seti (hQryHndl, cTblFld, iVal).
    
  end.
  
  method public logical dyn_seti   (input hQryHndl as handle, 
                                     input cTblFld as character, 
             input iVal as integer):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return false.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    assign hFldHndl:buffer-value = iVal.
    
    return true.
    
  end. /* method public dyn_setc() */
  
  /*****************************************************************************/
  /* Allow the setting of character type values.  No error checking - assume   */
  /* the programmer has a clue.                                                */
  /*****************************************************************************/
  
  method public logical dyn_setf   (input cTblFld as character, 
                                    input fVal as decimal):
                                      
    return dyn_setf(hQryHndl, cTblFld, fVal).                                      
               
  end.
  
  
  method public logical dyn_setf   (input hQryHndl as handle, 
                                     input cTblFld as character, 
             input fVal as decimal):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return false.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    assign hFldHndl:buffer-value = fVal.
    
    return true.
    
  end. /* method public dyn_setc() */
  
  /*****************************************************************************/
  /* Allow the setting of character type values.  No error checking - assume   */
  /* the programmer has a clue.                                                */
  /*****************************************************************************/

  method public logical dyn_setl   (input cTblFld as character, 
                                    input lVal as logical):
               
    return dyn_setl (hQryHndl, cTblFld, lVal).
    
  end.
  
    
  method public logical dyn_setl   (input hQryHndl as handle, 
                                     input cTblFld as character, 
             input lVal as logical):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return false.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    assign hFldHndl:buffer-value = lVal.
    
    return true.
    
  end. /* method public dyn_setc() */
  
  /*****************************************************************************/
  /* Allow the setting of character type values.  No error checking - assume   */
  /* the programmer has a clue.                                                */
  /*****************************************************************************/
  
  method public logical dyn_setd   (input cTblFld as character, 
                                    input dVal as date):
               
    return dyn_setd (hQryHndl, cTblFld, dVal).
    
  end.  
  
  
  method public logical dyn_setd   (input hQryHndl as handle, 
                                     input cTblFld as character, 
             input dVal as date):
  
    define variable hFldHndl as handle no-undo.
    define variable cValue as character no-undo.
    
    find ttDynToolKit exclusive-lock
    where ttDynToolKit.QryHndl = hQryHndl
      and ttDynToolKit.TblName = ENTRY(1, cTblFld, ".").
      
    if not available ttDynToolKit then return false.
    
    assign hFldHndl = ttDynToolKit.TblHndl:BUFFER-FIELD(entry(2, cTblFld, ".")).
   
    assign hFldHndl:buffer-value = dVal.
    
    return true.
    
  end. /* method public dyn_setc() */

  

end class.




/**************** tests

/* for each ecommerce.WebParam: display ecommerce.WebParam. */

define variable D as dyntoolkit no-undo.

// Good test

D = new dyntoolkit("for each webparam no-lock").

repeat:
  
  D:dyn_next().
  if D:dyn_qoe() then leave.
  
  display
  D:dyn_getvalue("WebParam.Name")
  D:dyn_getvalue("WebParam.Data")
  D:cDyn_ErrCode
  D:cDyn_ErrMsg
  with frame good title "good".
  
end.

delete object D.

// Bad Test - wrong table

D = new dyntoolkit("for each customer no-lock").

repeat:
  
  D:dyn_next().
  if D:dyn_qoe() then leave.
  
  display
  D:dyn_getvalue("WebParam.Name")
  D:dyn_getvalue("WebParam.Data")
  D:cDyn_ErrCode
  D:cDyn_ErrMsg
  with frame bad1 title "bad 1".
  
end.

delete object D.

// Bad test - no such table

D = new dyntoolkit("for each notable no-lock").

disp
  D:cDyn_ErrCode
  D:cDyn_ErrMsg format "x(40)" 
  .
  
repeat:
  
  D:dyn_next().
  if D:dyn_qoe() then leave.
  
  display
  D:dyn_getvalue("WebParam.Name")
  D:dyn_getvalue("WebParam.Data")
  D:cDyn_ErrCode
  D:cDyn_ErrMsg
  with frame bad2 title "bad 2".
  
end.

delete object D.

**************************/
