function iut_test::init, _extra=extra
  return, 1
end

pro iut_test::cleanup
end

pro iut_test::before
  
end

pro iut_test::after
  
end

function iut_test::_after
  compile_opt idl2, hidden
  catch, error
   if (error ne 0l) then begin
     catch, /cancel
     return, 0
   endif
    
   self->after
   
   return, 1
end

function iut_test::_before
  compile_opt idl2, hidden
  catch, error
   if (error ne 0l) then begin
     catch, /cancel
     return, 0
   endif
    
   self->before
   
   return, 1
end

pro iut_test::beforeclass
  
end

;function iut_test::_beforeclass
;  ;compile_opt idl2, hidden
;  ;catch, error
;  ; if (error ne 0l) then begin
;  ;   catch, /cancel
;  ;   stop
;  ;   return, 0
;  ; endif
;    
;   self->beforeclass
;   
;   return, 1
;end


pro iut_test::afterclass
   
end

;function iut_test::_afterclass
;   compile_opt idl2, hidden
;   ;catch, error
;   ;if (error ne 0l) then begin
;   ;  catch, /cancel
;   ;  return, 0
;   ;endif
;    
;   self->afterclass
;   
;   return, 1
;end


function iut_test::run_test, testcase, skip=skip, stoponerror=stoponerror
   default, skip, 0b
   default, stoponerror, 0
   
   res = {iut_testresult}
   
   res.class = obj_class(self)
   res.method = testcase
   res.instance = self
   if skip then begin
    res.duration = 0
    res.error_msg = "skiped"
    res.stack_trace = "skiped"
    res.result = 0
    return, res
   endif
   
   
   if ~stoponerror then begin
   
     catch, err_code
      if err_code ne 0 then begin
        catch, /Cancel
        res.result = 0;
        res.error_msg  = !ERROR_STATE.msg
        res.stack_trace = iut_err_message()
        res.duration = systime(1)-res.duration
        return, res
      endif
    end
    
    ok_testcase = 0b
    ok_after = 0b
    ok_before = self->_before()
    if ok_before then begin
      res.duration = systime(1)
      call_method, testcase, self
      res.duration = systime(1)-res.duration
      ok_testcase = 1b
      ok_after = self->_after()
    end
    
    res.result = ok_testcase && ok_before && ok_after
    
    return, res
end

function iut_test::find_tests

   tclass=obj_class(self)
   help,out=out,/rout
   regex='('+tclass+'::)(test_[^ ]+)( +)(.?)'
   chk=stregex(out,regex,/fold,/extra,/subex)
   resultlines = reform(strlowcase(chk[2,*]))
   ok=where(resultlines ne ''  ,count)
   if count gt 0 then begin
    methods=resultlines[ok]
   endif
  
   if not exist(methods) then methods=[]
   
   ;atach beforClass and afterClass to the list
   methods = ['beforeclass',methods,'afterclass']
   return,methods
end

function iut_test::run_alltest
  methods = self->find_tests()
  results = replicate({iut_testresult},n_elements(methods)) 
  for i=0l, n_elements(methods)-1 do results[i] = self->test(methods[i])
  return, results
end

pro iut_test__define
  compile_opt idl2, hidden
  
  void = {iut_test, void:0, inherits IDL_Object}
end
