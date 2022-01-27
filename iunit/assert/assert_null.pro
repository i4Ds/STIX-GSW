;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_NULL
;
; PURPOSE:
;       Verifies if a variable is !NULL.
;
; CALLING SEQUENCE:
;       ASSERT_NULL, variable=,[err_msg=]
;
; INPUTS:
;       variable  - the variable to verify
;       err_msg   - an optional error message which will be thrown
;                   if the variable is not !NULL
;
; EXAMPLES:
;       To verify if the variable a is !NULL:
;       IDL> a = []
;       IDL> ASSERT_NULL, a, "The variable is not !NULL!"
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
PRO assert_null, variable, err_msg
  IF ~isvalid(err_msg) THEN err_msg = "Assertation Error - variable is not null:" $
  + STRING(13B) + "variable: "+STRJOIN(trim(variable),",") 
  
  IF variable ne !NULL THEN $
    MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
END
