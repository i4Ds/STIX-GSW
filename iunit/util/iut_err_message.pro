;+
; PROJECT: 
;       IUnit - Heliopolis
;
; NAME:
;       ERR_MESSAGE
;
; PURPOSE:
;       Function which dumps a catched error message to a formated string
;
; CALLING SEQUENCE:
;       msg = ERR_MESSAGE()
;
; INPUTS:
;       None
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       a formated string with stack trace
;
; PROCEDURES/FUNCTIONS USED:
;       STR_SEP, HELP
;
; EXAMPLES:
;       To catch an error and print it to the console:
;          Catch, err_code
;          IF err_code NE 0 THEN BEGIN
;            CATCH, /Cancel
;            msg = ERR_MESSAGE()
;          ENDIF
;
; MODIFICATION HISTORY:
;       D. Vischi/R. Misteli, 2013 August 13, Initial
;       Nicky Hochmuth, 2013 August 21, add to IUnit
;
; COPYRIGHT
;        Copyright (C) 2013 University of Applied Sciences and Arts Northwestern Switzerland FHNW,
;        All Rights Reserved. Written by Nicky Hochmuth, D. Vischi and R. Misteli.
;        This code comes with no warranty.
;-
function iut_err_message
  str = ""
  Help, Calls=callStack
  callingRoutine = (STR_SEP(StrCompress(callStack[1])," "))[0]
  Help, /Last_Message, Output=traceback
  str += STRING(13B) + "Traceback Report from " + STRUPCASE(callingRoutine) + ":" + STRING(13B)
  str += strjoin(traceback,STRING(13B),/single)
  return, str
END