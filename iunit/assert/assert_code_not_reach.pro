;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       assert_code_not_reach
;
; PURPOSE:
;       Verifies if a variable is !NULL.
;
; CALLING SEQUENCE:
;       assert_code_not_reach, variable=,[err_msg=]
;
; INPUTS:
;       variable  - the variable to verify
;       err_msg   - an optional error message which will be thrown
;                   if the variable is not !NULL
;
; EXAMPLES:
;       To verify if a program sequence works as expected 
;       a = 1
;       if a eq 1 then print, "OK" else assert_code_not_reach
;
; MODIFICATION HISTORY:
;       Nicky Hochmuth, 2013 August 21, Initial
;
; COPYRIGHT
;        Copyright (C) 2013 University of Applied Sciences and Arts Northwestern Switzerland FHNW,
;        All Rights Reserved. Written by Nicky Hochmuth.
;        This code comes with no warranty.
;-
PRO assert_code_not_reach, err_msg
  IF ~isvalid(err_msg) THEN err_msg = "Assertation Error - code block was reached"
  MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
END
