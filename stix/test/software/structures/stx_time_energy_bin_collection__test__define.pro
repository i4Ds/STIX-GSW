pro stx_time_energy_bin_collection__test::beforeclass
  a = self->t_e_bin1(1,2,4,5,"a")
  b = self->t_e_bin1(2,4,6,10,"b")
  c = self->t_e_bin2(3,5,8,20,"c")
  d = self->t_e_bin2(2.5,3.5,7,8,"d")
  e = self->t_e_bin1(3.5,3.75,9,9.1,"e")
  
  p = self->t_e_bin1(10,12,7,9,"p")
  q = self->t_e_bin1(12,14,5,7,"q")
  r = self->t_e_bin1(12,14,7,9,"r")
  s = self->t_e_bin1(12,14,9,11,"s")
  t = self->t_e_bin1(14,16,7,9,"t")
  
  self.bins = ptr_new([ptr_new(a),ptr_new(b),ptr_new(c),ptr_new(d),ptr_new(e),ptr_new(p),ptr_new(q),ptr_new(r),ptr_new(s),ptr_new(t)])
end

pro stx_time_energy_bin_collection__test::afterclass

  ptr_free, self.bins
end

pro stx_time_energy_bin_collection__test::test_alter

  a = (*self.bins)[0]
  b = (*self.bins)[1]
  c = (*self.bins)[2]
  d = (*self.bins)[3]
  e = (*self.bins)[4]
  
  col = stx_time_energy_bin_collection([a,b,c])
  inter = col->select(/all)
  ;assert_equals, 3l, n_elements(inter)
  
  col->add, [d,e]
  
  assert_equals, 5l, n_elements(col->select(/all))
  
  col->remove, [2,3]
  
  assert_equals, 3l, n_elements(col->select(/all))
  
  col->remove, /all
  
  assert_equals, 0L, n_elements(col->select(/all))
  
  col->add, [c,d,e]
  
  assert_equals, 3L, n_elements(col->select(/all))
  
  col->remove, [0,1,2], type=ppl_typeof(*c)
  
  inter = col->select(/all)
  assert_equals, 1L, n_elements(inter)
  assert_equals, ppl_typeof(*e), ppl_typeof(*inter[0])
  
  destroy, col
  
end

pro stx_time_energy_bin_collection__test::test_typed

  a = (*self.bins)[0]
  b = (*self.bins)[1]
  c = (*self.bins)[2]
  d = (*self.bins)[3]
  e = (*self.bins)[4]
  
  col = stx_time_energy_bin_collection([a,b,c,d,e])
  inter = col->select(/all)
  assert_equals, 5L, n_elements(inter)
  
  
  inter = col->select(/all,type=ppl_typeof(*a))
  assert_equals, 3L, n_elements(inter)
  
  assert_equals, ppl_typeof(*a), ppl_typeof(inter[0])
  assert_equals, ppl_typeof(*a), ppl_typeof(inter[1])
  assert_equals, ppl_typeof(*a), ppl_typeof(inter[2])
  
  destroy, col
  
end

pro stx_time_energy_bin_collection__test::test_get_boundary

  a = (*self.bins)[0]
  b = (*self.bins)[1]
  c = (*self.bins)[2]
  d = (*self.bins)[3]
  e = (*self.bins)[4]
  
  col = stx_time_energy_bin_collection([a,b,c])
  
  trange =  col->get_boundingbox(/time)
  erange = col->get_boundingbox(/energy)
  range = col->get_boundingbox()
  
  assert_array_equals, [1d,5], anytim(trange.value)
  assert_array_equals, [4d,20], erange
  assert_array_equals, erange, range.energy
  assert_array_equals, anytim(trange.value), anytim(range.time.value)
  
end

pro stx_time_energy_bin_collection__test::test_select

  a = (*self.bins)[0]
  b = (*self.bins)[1]
  c = (*self.bins)[2]
  d = (*self.bins)[3]
  e = (*self.bins)[4]
  
  col = stx_time_energy_bin_collection([a,b,c])
  
  ;find all
  found = col->select(count_matches=count_matches)
  
  assert_equals, 3L, count_matches
  assert_array_equals, [(*a).id,(*b).id,(*c).id], [(*found[0]).id,(*found[1]).id,(*found[2]).id]
  
  ;find some
  found = col->select(time=[stx_construct_time(time=2.1),stx_construct_time(time=4)],count_matches=count_matches)
  assert_equals, 2L, count_matches
  assert_array_equals, [(*b).id,(*c).id], [(*found[0]).id,(*found[1]).id]
  
  ;find nothing
  found = col->select(time=stx_construct_time(time=2), energy=3, /strict, count_matches=count_matches)
  assert_equals, 0l, count_matches
  ;assert_null, found
  
  ;add 2 intervals
  col->add, [d,e]
  
  ;find all
  found = col->select(count_matches=count_matches)
  assert_equals, 5L, count_matches
  
  ;find some
  found = col->select(time=[stx_construct_time(time=2.1),stx_construct_time(time=4)],/strict,count_matches=count_matches)
  assert_equals, 2l, count_matches
  assert_array_equals, [(*d).id,(*e).id], [(*found[0]).id,(*found[1]).id]
  
end

;+
;
; :description:
;
;   this procedure runs the stx_time_energy_bin_collection::select method with a range of energy and time boundaries 
;   and the strict keyword set on a set of intervals with the format:
;
;            -----
;            | S |
;        -------------
;        | P | R | T |
;        -------------
;            | Q |
;            -----
;            
;   The test is passed if the expected intervals are retuned    
;           
;-
pro stx_time_energy_bin_collection__test::test_select_strict

  p = (*self.bins)[5]
  q = (*self.bins)[6]
  r = (*self.bins)[7]
  s = (*self.bins)[8]
  t = (*self.bins)[9]
  
  col = stx_time_energy_bin_collection([p,q,r,s,t])
  
  ; selected boundary between t = [11, 15] and e = [6, 10] passing through all outer intervals.
  ; With the strict keyword the center interval (R) should be returned
  found = col->select(time=[stx_construct_time(time=11),stx_construct_time(time=15)], energy = [6, 10],count_matches=count_matches,/strict)
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
  ; selected boundary between t = [12, 14] and e = [7, 9] coincident with boundaries of inner interval.
  ; With the strict keyword the center interval (R) should be returned
  found = col->select(time=[stx_construct_time(time=12),stx_construct_time(time=14)], energy = [7, 9],count_matches=count_matches,/strict)
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
  ; selected boundary between t = [11, 14] and e = [6, 9] coincident with upper boundaries of inner interval and passing through centers of P and Q.
  ; With the strict keyword the center interval (R) should be returned
  found = col->select(time=[stx_construct_time(time=11),stx_construct_time(time=14)], energy = [6, 9],count_matches=count_matches,/strict)
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
  ; selected boundary between t = [12, 15] and e = [7, 10] coincident with lower boundaries of inner interval (R) and passing through the centers of S and T.
  ; With the strict keyword the center interval (R) should be returned
  found = col->select(time=[stx_construct_time(time=12),stx_construct_time(time=15)], energy = [7, 10],count_matches=count_matches,/strict)
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
  ;single point at t = 12and e = 7 lower left corner of inner interval R.
  ;With the strict keyword for a single point a null result should be returned.
  found = col->select(time=[stx_construct_time(time=12)], energy = [7] ,count_matches=count_matches,/strict)
  assert_equals, 0L, count_matches
  
  ;single point at t = 12 and e = 7 upper time boundary of interval P.
  ;With the strict keyword interval P should be returned
  found = col->select(time=[stx_construct_time(time=12)], energy = [8] ,count_matches=count_matches,/strict)
  assert_equals, 0L, count_matches
  
  ;single point at t = 13 and e = 7 upper energy boundary of interval Q.
  ;With the strict keyword interval Q should be returned
  found = col->select(time=[stx_construct_time(time=13)], energy = [7] ,count_matches=count_matches,/strict)
  assert_equals, 0L, count_matches
  
  ;single point at t = 13 and e = 8 center of interval R.
  ;With the strict keyword interval R should be returned
  found = col->select(time=[stx_construct_time(time=13)], energy = [8] ,count_matches=count_matches,/strict)
  assert_equals, 0L, count_matches
  
  ;single point at t = 13 and e = 9 upper energy boundary of interval R.
  ;With the strict keyword interval R should be returned
  found = col->select(time=[stx_construct_time(time=13)], energy = [9] ,count_matches=count_matches,/strict)
  assert_equals, 0L, count_matches
  
  ;single point at t = 14 and e = 8 upper time boundary of interval R.
  ;With the strict keyword interval R should be returned
  found = col->select(time=[stx_construct_time(time=14)], energy = [8] ,count_matches=count_matches,/strict)
  assert_equals, 0L, count_matches
  
end

;+
;
; :description:
;
;   this procedure runs the stx_time_energy_bin_collection::select method with a range of energy and time boundaries 
;   and the strict keyword not set on a set of intervals with the format:
;
;            -----
;            | S |
;        -------------
;        | P | R | T |
;        -------------
;            | Q |
;            -----
;            
;   The test is passed if the expected intervals are retuned    
;           
;-
pro stx_time_energy_bin_collection__test::test_select_lenient

  p = (*self.bins)[5]
  q = (*self.bins)[6]
  r = (*self.bins)[7]
  s = (*self.bins)[8]
  t = (*self.bins)[9]
  
  col = stx_time_energy_bin_collection([p,q,r,s,t])
  
 
  ; selected boundary between t = [11, 15] and e = [6, 10] passing through all outer intervals.
  ; Without strict keyword all 5 should be returned  found = col->select(time=[stx_construct_time(time=11),stx_construct_time(time=15)], energy = [6, 10],count_matches=count_matches )
  assert_equals, 5L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), [ 'p', 'q', 'r', 's', 't']
  
  ; selected boundary between t = [12, 14] and e = [7, 9] coincident with boundaries of inner interval.
  ; Without strict keyword the inner interval and intervals with an upper boundary corresponding to the inner interval should be selected
  found = col->select(time=[stx_construct_time(time=12),stx_construct_time(time=14)], energy = [7, 9],count_matches=count_matches )
  assert_equals, 3L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), [ 'p', 'q', 'r']
  
  ; selected boundary between t = [11, 14] and e = [6, 9] coincident with upper boundaries of inner interval and passing through centers of P and Q.
  ; Without strict keyword the inner interval and P and Q should be returned
  found = col->select(time=[stx_construct_time(time=11),stx_construct_time(time=14)], energy = [6, 9],count_matches=count_matches )
  assert_equals, 3L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), [ 'p', 'q', 'r']
  
  ; selected boundary between t = [11, 14] and e = [6, 9] coincident with lower boundaries of inner interval (R) and passing through the centers of S and T.
  ; Without strict keyword all 5 should be returned
  found = col->select(time=[stx_construct_time(time=12),stx_construct_time(time=15)], energy = [7, 10],count_matches=count_matches )
  assert_equals, 5L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), [ 'p', 'q', 'r', 's', 't']
  
  ; single point at t = 12and e = 7 lower left corner of inner interval R.
  ; Without strict keyword  no intervals should be returned
  found = col->select(time=[stx_construct_time(time=12)], energy = [7] ,count_matches=count_matches )
  assert_equals, 0L, count_matches
  
  ;single point at t = 12 and e = 7 upper time boundary of interval P.
  ;Without strict keyword interval P should be returned
  found = col->select(time=[stx_construct_time(time=12)], energy = [8] ,count_matches=count_matches )
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['p']
  
  ;single point at t = 13 and e = 7 upper energy boundary of interval Q.
  ;Without strict keyword interval Q should be returned
  found = col->select(time=[stx_construct_time(time=13)], energy = [7] ,count_matches=count_matches )
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['q']
  
  
  ;single point at t = 13 and e = 8 center of interval R.
  ;Without strict keyword interval R should be returned
  found = col->select(time=[stx_construct_time(time=13)], energy = [8] ,count_matches=count_matches )
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
  
  ;single point at t = 13 and e = 9 upper energy boundary of interval R.
  ; Without strict keyword interval R should be returned
  found = col->select(time=[stx_construct_time(time=13)], energy = [9] ,count_matches=count_matches )
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
  
  ;Single point at t = 14 and e = 8 upper time boundary of interval R.
  ; Without strict keyword interval R should be returned
  found = col->select(time=[stx_construct_time(time=14)], energy = [8] ,count_matches=count_matches )
  assert_equals, 1L, count_matches
  found_tags = list()
  for i = 0,n_elements(found)-1 do found_tags.add, (*found[i]).id
  assert_array_equals, found_tags.toarray(), ['r']
  
end



function stx_time_energy_bin_collection__test::t_e_bin1, t_start, t_end, e_start, e_end, id

  void = {$
    type          : 'test_t_e_bin1', $
    time_range    : [stx_construct_time(time=t_start),stx_construct_time(time=t_end)], $
    energy_range  : [float(e_start),float(e_end)], $
    id            : trim(id), $
    adddate       : dist(10,20) $
    }
    
  return, void
  
end

function stx_time_energy_bin_collection__test::t_e_bin2, t_start, t_end, e_start, e_end, id

  void = {$
    type          : 'test_t_e_bin2', $
    time_range    : [stx_construct_time(time=t_start),stx_construct_time(time=t_end)], $
    energy_range  : [float(e_start),float(e_end)], $
    id            : trim(id), $
    map           : make_map(dist(10,10)) $
    }
    
  return, void
  
end

pro stx_time_energy_bin_collection__test__define
  compile_opt idl2, hidden
  
  void = { stx_time_energy_bin_collection__test, $
    bins : ptr_new(), $
    inherits iut_test }
end
