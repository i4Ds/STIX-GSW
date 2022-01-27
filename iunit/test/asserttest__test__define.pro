pro asserttest__test::test_assert_equals
  assert_equals, 4, 2+1
end

pro asserttest__test::test_assert_false
    assert_false, 2 gt 3
end 

pro asserttest__test::test_assert_true
    assert_true, 2 eq 3
end 

pro asserttest__test::test_assert_not_null
    assert_not_null, 1
end 

pro asserttest__test::test_assert_null
    assert_null, []
end

pro asserttest__test::test_assert_array_equals
    t = fix(dist(300,300))
    t2 = t+1
    assert_array_equals, t,t2-1
end

pro asserttest__test::test_assert_code_not_reach
    a = 1
    if a eq 1 then print, "OK" else assert_code_not_reach 
end

pro asserttest__test__define
  compile_opt idl2, hidden
  
  void = { asserttest__test, $
    inherits iut_test }
end
