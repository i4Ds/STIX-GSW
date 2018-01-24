; If assertion is not true, throw error and return to caller
;
PRO assert, assertion
  on_error, 2
  IF NOT assertion THEN message, "Assertion failed"
END 
