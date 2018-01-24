;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       assert_same_data
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
;       ASSERT_same_data, [1,2,3], [1,2,4]
;
; MODIFICATION HISTORY:
;       Nicky Hochmuth, 2014 January 09, add to IUnit
;
; COPYRIGHT
;        Copyright (C) 2013 University of Applied Sciences and Arts Northwestern Switzerland FHNW,
;        All Rights Reserved. Written by Nicky Hochmuth
;        This code comes with no warranty.
;-
PRO assert_same_data, expecteds, actuals, err_msg
    
  IF NOT same_data2(expecteds, actuals) THEN begin
    IF ~isvalid(err_msg) THEN err_msg = "Assertation Error - data not equal"
    MESSAGE, err_msg, /NoPrint, /NoName, /NoPrefix
  endif
END
