;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_LIST_EQUALS
;
; PURPOSE:
;       Verifies if two lists are equal.
;
; CALLING SEQUENCE:
;       ASSERT_LIST_EQUALS, expecteds=,actuals=,[err_msg=]
;
; INPUTS:
;       expecteds   - the first list to verify
;       actuals     - the second list to verify
;       err_msg     - an optional error message which will be thrown
;                     if the two lists are not equal
;
; PROCEDURES/FUNCTIONS USED:
;       ARRAY_EQUAL
;
; EXAMPLES:
;       To verify the lists LIST(1) and LIST(2):
;          IDL> ASSERT_LIST_EQUALS, LIST(1), LIST(2), "The lists are not equal!"
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
PRO assert_list_equals, expecteds, actuals, err_msg
  
  expecteds_array=expecteds->toArray()
  actuals_array=actuals->toArray()
  
  
  
  IF NOT ARRAY_EQUAL(expecteds, actuals, /NO_TYPECONV) THEN begin
    IF ~isvalid(err_msg) THEN err_msg = "Assertation Error - lists not equal:" $
      + STRING(13B) + "expected: "+STRJOIN(trim(expecteds),",",/single) $
      + STRING(13B) + "actual  : "+STRJOIN(trim(actuals),",",/single)
      MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
    endif
END
