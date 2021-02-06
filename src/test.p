
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

DEFINE VARIABLE cRCS AS CHARACTER INIT "$Id: test.p,v 1.3 2006/06/27 02:02:13 sauge Exp $" NO-UNDO.

DEFINE VARIABLE h AS HANDLE NO-UNDO.

/****************************************************************/
/* Test One : A good query in DB 1                              */
/****************************************************************/
  
HIDE ALL.
MESSAGE "Good Test".

ASSIGN h = dyn_open("FOR EACH Job NO-LOCK").

DISPLAY cDyn_ErrCode cDyn_ErrMsg FORMAT "x(30)".

DISPLAY h:NUM-RESULTS COLUMN-LABEL "NumResults".

REPEAT:

  dyn_next(h).
  IF dyn_qoe(h) THEN LEAVE.
	  
  DISPLAY dyn_getvalue(h, "Job.JobID")
          dyn_getvalue(h, "Job.Name")
	  dyn_getvalue(h, "Job.Priority")
	  dyn_getvalue(h, "Job.ErrCode").
	  
END.
  
dyn_close(h).

PAUSE.

/****************************************************************/
/* Test One : A bad query in DB 1 & DB 2                        */
/****************************************************************/

HIDE ALL.
MESSAGE "Bad Test".

ASSIGN h = dyn_open("FOR EACH NoTable NO-LOCK").

DISPLAY cDyn_ErrCode cDyn_ErrMsg  FORMAT "x(30)".
                                              
IF h <> ? THEN DO:

  REPEAT:
  
    dyn_next(h).
    IF dyn_qoe(h) THEN LEAVE.
  	  
    DISPLAY dyn_getvalue(h, "Job.JobID")
            dyn_getvalue(h, "Job.Name")
  	  dyn_getvalue(h, "Job.Priority")
  	  dyn_getvalue(h, "Job.ErrCode").
  	  
  END.
    
  dyn_close(h).

END.

/****************************************************************/
/* Test Three : A good query in DB 2                            */
/****************************************************************/
  
HIDE ALL.
MESSAGE "Good Test".

ASSIGN h = dyn_open("FOR EACH Person NO-LOCK").

DISPLAY cDyn_ErrCode cDyn_ErrMsg FORMAT "x(30)".

DISPLAY h:NUM-RESULTS COLUMN-LABEL "NumResults".

REPEAT:

  dyn_next(h).
  IF dyn_qoe(h) THEN LEAVE.
	  
  DISPLAY dyn_getvalue(h, "Person.FirstName")
          dyn_getvalue(h, "Person.LastName").
	  
END.
  
dyn_close(h).

PAUSE.
