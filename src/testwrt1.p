
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
 
{dyntoolkit.i}

DEFINE VARIABLE cRCS AS CHARACTER INIT "$Id: testwrt1.p,v 1.1 2006/06/30 05:13:54 sauge Exp sauge $" NO-UNDO.

DEFINE VARIABLE h AS HANDLE NO-UNDO.

DEFINE VARIABLE c AS CHARACTER NO-UNDO.


/****************************************************************/
/* Test One : A good query in DB 1 with a write to the buffers  */
/****************************************************************/
  
HIDE ALL.

ASSIGN h = dyn_open("FOR EACH Job EXCLUSIVE-LOCK").

DISPLAY cDyn_ErrCode cDyn_ErrMsg FORMAT "x(30)".

DISPLAY h:NUM-RESULTS COLUMN-LABEL "NumResults".

/**************************************************************/
/* Note with an exclusive lock, we need TRANSACTION for our   */
/* looping.                                                   */
/**************************************************************/
    
REPEAT TRANSACTION:

  dyn_next(h).
  IF dyn_qoe(h) THEN LEAVE.
	  
  DISPLAY dyn_getvalue(h, "Job.JobID")
          dyn_getvalue(h, "Job.Name")
	  dyn_getvalue(h, "Job.Priority")
	  dyn_getvalue(h, "Job.ErrCode").
	  
  /**************************************************************/
  /* Check our write ability                                    */
  /**************************************************************/
 
  /**************************************************************/  
  /* In this table, the JobID is used to order the query.  When */
  /* updating this value, the query tends to spin off to la-la  */
  /* land. Reading it works just fine so no worries there.      */
  /* This is an example of code that will NOT work.             */
  /* You will need to deal with this problem programmatically.  */
  /* JobID is a primary unique index in the Job table.          */
  /**************************************************************/    
  
  /* dyn_setc(h, "Job.JobID", STRING(TIME)).*/ 
  


  /**************************************************************/  
  /* These are indexed, but not involved in the ordering of     */
  /* the query - so there is no problem.                        */
  /**************************************************************/
  
  /**************************************************************/
  /* Note unlike testwrt.p, we are using dyn_set which will     */
  /* figure out the data type according to the field and at-    */
  /* tempt to type cast according to that for setting the value.*/
  /**************************************************************/
  
  dyn_set(h, "Job.STATE", "CRAIG").  
  dyn_set(h, "Job.Priority", STRING(TIME)).
  dyn_set(h, "Job.ALogical", "YES").
  dyn_set(h, "Job.PrcStartDate", STRING(TODAY)).
  dyn_set(h, "Job.ADecimal", STRING(4.22)).

  PAUSE 1.
	  
END.
  
dyn_close(h).

/****************************************************************/
/* See if the writes took.                                      */
/****************************************************************/

PAUSE.

HIDE ALL.

FOR EACH Job NO-LOCK:
	
  DISPLAY Job.
  DISPLAY Job.JobID FORMAT "x(30)" with side-labels.

END.
