pro assertfail__test::test_assert_equals
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end

    assert_equals, 4, 2-2,"ASSERT_FAIL"
end

pro assertfail__test::test_assert_false
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end
      
    assert_equals, 2,2
    assert_false, 2 eq 2,"ASSERT_FAIL"
end 

pro assertfail__test::test_assert_true
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end

    assert_true, 2 ne 2,"ASSERT_FAIL"
end 

pro assertfail__test::test_assert_not_null
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end

    assert_not_null, [],"ASSERT_FAIL"
end 

pro assertfail__test::test_assert_null
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end

    assert_null, 1,"ASSERT_FAIL"
end

pro assertfail__test::test_assert_array_equals
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end
    assert_array_equals, [1,2,3],[2,4,6],"ASSERT_FAIL"
end

pro assertfail__test::test_assert_code_not_reach
    catch, err_code
    if err_code ne 0 then begin
      catch, /Cancel
      if strcmp(!ERROR_STATE.msg,"ASSERT_FAIL",/fold_case) then return
      MESSAGE, !ERROR_STATE.msg, /NoPrint, /NoName, /NoPrefix
    end
    
    a = 1
    if a eq 1 then assert_code_not_reach, "ASSERT_FAIL" else print, "OK"
    
    assert_code_not_reach
end


pro assertfail__test__define
  compile_opt idl2, hidden
  
  void = { assertfail__test, $
    inherits iut_test }
end
