;+
; PROJECT:
;       IUnit - Heliopolis
;
; NAME:
;       ASSERT_EQUALS
;
; PURPOSE:
;       Verifies if a value is in given range
;
; CALLING SEQUENCE:
;       ASSERT_IN_RANGE, expected_range, actual ,[err_msg], range=range, include=include
;
; INPUTS:
;       expected_range  - the expected value to verify
;       actual          - the actual value to verify
;       err_msg         - an optional error message which will be thrown
;                     if the two values are not equal
;
; KEYWORD PARAMETERS:
;       range  -  if present the range is generated as persentage of the scalar value of expected_range
;       include  - if keyword pressent the range is expected as (a,b) else [a,b]
;
; EXAMPLES:
;       To verify the values 3 is between 1 and 4:
;          IDL> ASSERT_IN_RANGE, [1,4], 2, "The value is not in range!"
;
; MODIFICATION HISTORY:
;       Nicky Hochmuth, 2018 Jan 26, FHNW Initial
;
;-
pro assert_in_range, expected_range, actual ,err_msg, range=range, include=include

  if isa(range) then expected_range = [expected_range-(expected_range*range),expected_range+(expected_range*range)]

  if keyword_set(include) then begin
    assert_true, actual le expected_range[1] and actual ge expected_range[0], err_msg 
  end else begin 
    assert_true, actual lt expected_range[1] and actual gt expected_range[0], err_msg
  end

end