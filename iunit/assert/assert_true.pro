;+
; PROJECT:
;       RheSSI FC
;
; NAME:
;       ASSERT_TRUE
;
; PURPOSE:
;       Verifies if an expression is TRUE.
;;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_TRUE
;
; PURPOSE:
;       Verifies if an expression is TRUE
;
; CALLING SEQUENCE:
;       ASSERT_TRUE, expression=,[err_msg=]
;
; INPUTS:
;       expression  - the expression to verify
;       err_msg     - an optional error message which will be thrown
;                     if the expression is not TRUE
;
; EXAMPLES:
;       To verify if the expression '1 NE 2' is TRUE:
;          IDL> ASSERT_TRUE, 1 NE 2, "The expression is FALSE!"
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
PRO assert_true, expression, err_msg
  IF ~isvalid(err_msg) THEN err_msg = "Assertation Error - expression not true:" $
  + STRING(13B) + "expression: "+STRJOIN(trim(expression),",")
  
  IF expression eq 0 THEN  MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
END


