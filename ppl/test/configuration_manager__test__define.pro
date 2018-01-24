

;+
; init at object instanciation
;-
pro configuration_manager__test::beforeclass


end


;+
; cleanup at object destroy
;-
pro configuration_manager__test::afterclass


end

;+
; cleanup after each test case
;-
pro configuration_manager__test::after
  destroy, *self.cfm
  assert_null, *self.cfm
end

;+
; init before each test case
;-
pro configuration_manager__test::before
  path = curdir()+ path_sep() +"ppl"+path_sep()+"test"
  self.cfm = ptr_new(stx_configuration_manager(configpath=path))
  assert_true, is_object(*self.cfm)
end

pro configuration_manager__test::test_loadconfig

  conf = (*self.cfm)->get()
  assert_true, ppl_typeof(conf, compareto="ppl_configuration")
  assert_true, conf.module eq "global"
 
end

pro configuration_manager__test::test_pplcase

  conf = (*self.cfm)->get(module="stx_module_create_map")
  assert_true, ppl_typeof(conf, compareto="ppl_configuration")
  assert_true, conf.module eq "stx_module_create_map"
  
  help, conf
  
  assert_true, conf.algo eq "uvsmooth"
  assert_true, tag_exist(conf,'testparam')
  assert_equals, conf.testparam, 2 
  
  (*self.cfm)->set, img_algo = 'clean'
  
  conf = (*self.cfm)->get(module="stx_module_create_map")
  
  assert_true, conf.algo eq "clean"
  assert_false, tag_exist(conf,'testparam')
  assert_true, tag_exist(conf,'niter')
  assert_equals, conf.niter, 100 
  
  (*self.cfm)->set, img_niter = 'test', subcase="algo.clean"
  conf = (*self.cfm)->get(module="stx_module_create_map")
  assert_equals, conf.niter, 'test'
  
end


;+
; Define instance variables.
;-
pro configuration_manager__test__define
  compile_opt idl2, hidden
  
  define = { configuration_manager__test, $
    ;your class variables here
    cfm : ptr_new(), $
    inherits iut_test }
end

