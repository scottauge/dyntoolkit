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

/****************************************************************************/
/* This defines a query and then sends that query to an external procedure. */
/* In the external procedure one uses dyn_qryinfo() to build up it's goods  */
/* and then use the APIs as expected.                                       */
/****************************************************************************/

{dyntoolkit.i}


DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.

/****************************************************************************/
/* Prep data structures from passed in handle for use with dyntoolkit APIs  */
/****************************************************************************/

dyn_qryinfo(h).

/****************************************************************************/
/* Do a nice little loop to show the idea works and dyn_qryinfo() works.    */
/****************************************************************************/

REPEAT:

  dyn_next(h).
  IF dyn_qoe(h) THEN LEAVE.
	  
  DISPLAY dyn_getvalue(h, "Job.JobID")
          dyn_getvalue(h, "Job.Name")
	  dyn_getvalue(h, "Job.Priority")
	  dyn_getvalue(h, "Job.ErrCode").
	  
END.
