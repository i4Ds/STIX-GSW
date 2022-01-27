;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_FALSE
;
; PURPOSE:
;       Verifies if an expression is FALSE.
;
; CALLING SEQUENCE:
;       ASSERT_FALSE, expression=,[err_msg=]
;
; INPUTS:
;       expression  - the expression to verify
;       err_msg     - an optional error message which will be thrown
;                     if the expression is not FALSE
;
; EXAMPLES:
;       To verify if the expression '1 NE 2' is FALSE:
;          IDL> ASSERT_FALSE, 1 NE 2, "The expression is TRUE!"
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
PRO assert_false, expression, err_msg
  IF ~isvalid(err_msg) THEN err_msg = "Assertation Error - expression not false:" $
  + STRING(13B) + "expression: "+STRJOIN(trim(expression),",")
  
  IF not(expression eq 0) THEN $
    MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
END
