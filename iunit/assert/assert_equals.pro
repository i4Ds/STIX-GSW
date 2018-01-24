;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_EQUALS
;
; PURPOSE:
;       Verifies if two values are equal.
;
; CALLING SEQUENCE:
;       ASSERT_EQUALS, expecteds=,actuals=,[err_msg=]
;
; INPUTS:
;       expecteds   - the expected value to verify
;       actuals     - the actual value to verify
;       err_msg     - an optional error message which will be thrown
;                     if the two values are not equal
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;
; PROCEDURES/FUNCTIONS USED:
;       -
;
; EXAMPLES:
;       To verify the values 1 and 2:
;          IDL> ASSERT_EQUALS, 1, 2, "The values are not equal!"
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
PRO assert_equals, expecteds, actuals, err_msg
  assert_array_equals, expecteds, actuals, err_msg
END