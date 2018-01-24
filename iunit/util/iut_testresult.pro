function iut_testresult, class, method, result, error_msg, duration, instance=instance
  res = {iut_testresult}
  
  default, class, ""
  default, method, ""
  default, error_msg, ""
  default, result, 0b 
  default, duration, .0d
  
  
  
  res.class = class
  res.error_msg = error_msg
  res.method = method
  res.result = result
  res.duration = duration
  
  if isa(instance) then res.instance = instance
  return, res
end