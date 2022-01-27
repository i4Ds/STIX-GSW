;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_ARRAY_EQUALS
;
; PURPOSE:
;       Verifies if two arrays are equal.
;
; CALLING SEQUENCE:
;       ASSERT_ARRAY_EQUALS, expecteds=,actuals=,[err_msg=]
;
; INPUTS:
;       expecteds   - the first array to verify
;       actuals     - the second array to verify
;       err_message - an optional error message which will be thrown
;                     if the two arrays are not equal
;
; EXAMPLES:
;       To verify the arrays '[1,2,3]' and '[1,2,4]':
;       ASSERT_ARRAY_EQUALS, [1,2,3], [1,2,4]
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
PRO assert_array_equals, expecteds, actuals, err_msg
    
  IF NOT ARRAY_EQUAL(expecteds, actuals) THEN begin
    err_head = "Assertation Error - arrays not equal:" $
    + STRING(13B) + "expected: "+STRJOIN(trim(expecteds),",",/single) $
    + STRING(13B) + "actual  : "+STRJOIN(trim(actuals),",",/single)
    
    err_msg = isa(err_msg, "string") ? err_head + STRING(13B) +  err_msg : err_head
    
    MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
  endif
END
