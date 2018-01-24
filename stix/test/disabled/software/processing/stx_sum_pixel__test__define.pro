
; The pixel data [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ] is mapped as
;    |     |     |     |     |
;    |  1  |  2  |  3  |  4  |
;    |     |     |     |     |
;    -| 9|--|10|--|11|--|12|--
;    |     |     |     |     |
;    |  5  |  6  |  7  |  8  |
;    |     |     |     |     |

pro stx_sum_pixel__test::test_single1
  
  pd = stx_pixel_data()
  
  for i=0, 31 do pd.counts[i,*] = [1,1,1,1,2,2,2,2,3,3,3,3] * i

  
  assert_true, ppl_typeof(pd,compareto='stx_pixel_data',/raw)
  
  ;info = 'Sum counts over two big pixels'
  pds = stx_pixel_sums(pd,0)
  assert_true, ppl_typeof(pds,compareto='stx_pixel_data_summed',/raw)
  assert_equals, n_elements(pds.counts), 32*4
  assert_equals, total(pds.counts[0,*]), 0
  assert_equals, total(pds.counts[1,*]), 4*1+4*2
  assert_equals, total(pds.counts[2,*]), 2*(4*1+4*2)
  assert_equals, total(pds.counts[30,*]), 30*(4*1+4*2)
    
  ;info = 'Sum counts over two big pixels and small pixel'
  pds = stx_pixel_sums(pd,1)
  assert_equals, total(pds.counts[0,*]), 0
  assert_equals, total(pds.counts[1,*]), 4*1+4*2+4*3
  assert_equals, total(pds.counts[2,*]), 2*(4*1+4*2+4*3)
  assert_equals, total(pds.counts[30,*]), 30*(4*1+4*2+4*3)
  
  ;info = 'Only upper row pixels'
  pds = stx_pixel_sums(pd,2)
  assert_equals, total(pds.counts[0,*]), 0
  assert_equals, total(pds.counts[1,*]), 4*1
  assert_equals, total(pds.counts[2,*]), 2*(4*1)
  assert_equals, total(pds.counts[30,*]), 30*(4*1)

  ;info = 'Only lower row pixels'
  pds = stx_pixel_sums(pd,3)
  assert_equals, total(pds.counts[0,*]), 0
  assert_equals, total(pds.counts[1,*]), 4*2
  assert_equals, total(pds.counts[2,*]), 2*(4*2)
  assert_equals, total(pds.counts[30,*]), 30*(4*2)

  ;info = 'Only small pixels'
  pds = stx_pixel_sums(pd,4)
  assert_equals, total(pds.counts[0,*]), 0
  assert_equals, total(pds.counts[1,*]), 4*3
  assert_equals, total(pds.counts[2,*]), 2*(4*3)
  assert_equals, total(pds.counts[30,*]), 30*(4*3)
  
end

pro stx_sum_pixel__test::test_single2
  
  pd = stx_pixel_data()
  
  for i=0, 31 do pd.counts[i,*] = [1,1,1,1,2,2,2,2,3,3,3,3] + i

  
  assert_true, ppl_typeof(pd,compareto='stx_pixel_data',/raw)
  
  ;info = 'Sum counts over two big pixels'
  pds = stx_pixel_sums(pd,0)
  assert_true, ppl_typeof(pds,compareto='stx_pixel_data_summed',/raw)
  assert_equals, n_elements(pds.counts), 32*4
  assert_equals, total(pds.counts[0,*]), 4*1+4*2
  assert_equals, total(pds.counts[1,*]), 4*2+4*3
  assert_equals, total(pds.counts[2,*]), 4*3+4*4
  assert_equals, total(pds.counts[30,*]),4*31+4*32
  
  ;info = 'Sum counts over two big pixels and small pixel'
  pds = stx_pixel_sums(pd,1)
  assert_equals, total(pds.counts[0,*]), 4*1+4*2+4*3
  assert_equals, total(pds.counts[1,*]), 4*2+4*3+4*4
  assert_equals, total(pds.counts[2,*]), 4*3+4*4+4*5
  assert_equals, total(pds.counts[30,*]), 4*31+4*32+4*33
  
  ;info = 'Only upper row pixels'
  pds = stx_pixel_sums(pd,2)
  assert_equals, total(pds.counts[0,*]), 4*1
  assert_equals, total(pds.counts[1,*]), 4*2
  assert_equals, total(pds.counts[2,*]), 4*3
  assert_equals, total(pds.counts[30,*]), 4*31
  
  ;info = 'Only lower row pixels'
  pds = stx_pixel_sums(pd,3)
  assert_equals, total(pds.counts[0,*]), 4*2
  assert_equals, total(pds.counts[1,*]), 4*3
  assert_equals, total(pds.counts[2,*]), 4*4
  assert_equals, total(pds.counts[30,*]),4*32
  
  ;info = 'Only small pixels'
  pds = stx_pixel_sums(pd,4)
  assert_equals, total(pds.counts[0,*]), 4*3
  assert_equals, total(pds.counts[1,*]), 4*4
  assert_equals, total(pds.counts[2,*]), 4*5
  assert_equals, total(pds.counts[30,*]),4*33
  
end


pro stx_sum_pixel__test::test_multi
  
  pd1 = stx_pixel_data()
  for i=0, 31 do pd1.counts[i,*] = [1,1,1,1,2,2,2,2,3,3,3,3] * i
  
  pd2 = stx_pixel_data()
  for i=0, 31 do pd2.counts[i,*] = [1,1,1,1,2,2,2,2,3,3,3,3] + i
  
  all_pd = [pd1,pd2]
  
  assert_true, ppl_typeof(all_pd,compareto='stx_pixel_data_array')
  
  ;info = 'Sum counts over two big pixels'
  pds = stx_pixel_sums(all_pd,0)
  assert_true, ppl_typeof(pds,compareto='stx_pixel_data_summed_array')
  assert_equals, n_elements(pds.counts), 32*4*2
  
  assert_equals, total(pds[0].counts[0,*]), 0
  assert_equals, total(pds[0].counts[1,*]), 4*1+4*2
  assert_equals, total(pds[0].counts[2,*]), 2*(4*1+4*2)
  assert_equals, total(pds[0].counts[30,*]), 30*(4*1+4*2)

  assert_equals, total(pds[1].counts[0,*]), 4*1+4*2
  assert_equals, total(pds[1].counts[1,*]), 4*2+4*3
  assert_equals, total(pds[1].counts[2,*]), 4*3+4*4
  assert_equals, total(pds[1].counts[30,*]),4*31+4*32
    
  ;info = 'Sum counts over two big pixels and small pixel'
  pds = stx_pixel_sums(all_pd,1)
  assert_equals, total(pds[0].counts[0,*]), 0
  assert_equals, total(pds[0].counts[1,*]), 4*1+4*2+4*3
  assert_equals, total(pds[0].counts[2,*]), 2*(4*1+4*2+4*3)
  assert_equals, total(pds[0].counts[30,*]), 30*(4*1+4*2+4*3)

  assert_equals, total(pds[1].counts[0,*]), 4*1+4*2+4*3
  assert_equals, total(pds[1].counts[1,*]), 4*2+4*3+4*4
  assert_equals, total(pds[1].counts[2,*]), 4*3+4*4+4*5
  assert_equals, total(pds[1].counts[30,*]), 4*31+4*32+4*33
  
  ;info = 'Only upper row pixels'
  pds = stx_pixel_sums(all_pd,2)
  assert_equals, total(pds[0].counts[0,*]), 0
  assert_equals, total(pds[0].counts[1,*]), 4*1
  assert_equals, total(pds[0].counts[2,*]), 2*(4*1)
  assert_equals, total(pds[0].counts[30,*]), 30*(4*1)

  assert_equals, total(pds[1].counts[0,*]), 4*1
  assert_equals, total(pds[1].counts[1,*]), 4*2
  assert_equals, total(pds[1].counts[2,*]), 4*3
  assert_equals, total(pds[1].counts[30,*]), 4*31

  ;info = 'Only lower row pixels'
  pds = stx_pixel_sums(all_pd,3)
  assert_equals, total(pds[0].counts[0,*]), 0
  assert_equals, total(pds[0].counts[1,*]), 4*2
  assert_equals, total(pds[0].counts[2,*]), 2*(4*2)
  assert_equals, total(pds[0].counts[30,*]), 30*(4*2)

  assert_equals, total(pds[1].counts[0,*]), 4*2
  assert_equals, total(pds[1].counts[1,*]), 4*3
  assert_equals, total(pds[1].counts[2,*]), 4*4
  assert_equals, total(pds[1].counts[30,*]),4*32

  ;info = 'Only small pixels'
  pds = stx_pixel_sums(all_pd,4)
  assert_equals, total(pds[0].counts[0,*]), 0
  assert_equals, total(pds[0].counts[1,*]), 4*3
  assert_equals, total(pds[0].counts[2,*]), 2*(4*3)
  assert_equals, total(pds[0].counts[30,*]), 30*(4*3)

  assert_equals, total(pds[1].counts[0,*]), 4*3
  assert_equals, total(pds[1].counts[1,*]), 4*4
  assert_equals, total(pds[1].counts[2,*]), 4*5
  assert_equals, total(pds[1].counts[30,*]),4*33
  
end

;+
; Define instance variables.
;-
pro stx_sum_pixel__test__define
  compile_opt idl2, hidden
  
  define = { stx_sum_pixel__test, $
    ;your class variables here
    inherits iut_test }
end

