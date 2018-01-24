;+
; :FILE_COMMENTS:
;   This is a test class for scenario-based testing; specifically the variance calculation test
;
; :CATEGORIES:
;   data simulation, flight software simulator, software, testing
;
; :EXAMPLES:
;  res = iut_test_runner('stx_bitStreamRW__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;  res = iut_test_runner('stx_bitStreamRW__test')
;
; :HISTORY:
; 30-Nov-2015 - ECMD (Graz), initial release
; 10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accomodate structure changes
;
;-

;+
; :DESCRIPTION:
;    this function initializes this module; make sure to adjust the variables "self.test_name" and "self.test_type";
;    they will control, where in $STX_SCN_TEST to look for this test's scenario and configuration files
;    (e.g. $STX_SCN_TEST/basic/calib_spec_acc)
;
; :KEYWORDS:
;   extra : in, optional
;     extra parameters interpreted by the base class (see stx_scenario_test__define)
;
; :RETURNS:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_bitStreamRW__test::init, _extra=extra
  td = replicate({ data : ulong64(0), bits : 0b, type: 0b }, 10)
  
  td[0].data = 6          & td[0].bits = 5      & td[0].type = 1
  td[1].data = 600        & td[1].bits = 11     & td[1].type = 2
  td[2].data = 6000       & td[2].bits = 13     & td[2].type = 3
  td[3].data = uint(-1)   & td[3].bits = 16     & td[3].type = 12
  td[4].data = ulong(-1)  & td[4].bits = 32     & td[4].type = 13
  td[5].data = long64(17) & td[5].bits = 12     & td[5].type = 14
  td[6].data = ulong64(18)& td[6].bits = 9      & td[6].type = 15
  td[7].data = 6          & td[7].bits = 5      & td[7].type = 1
  td[8].data = 7          & td[8].bits = 6      & td[8].type = 1
  td[9].data = 8          & td[9].bits = 7      & td[9].type = 1

  
  self.testdata = ptr_new(td)
  return, self->iut_test::init(_extra=extra)
end


;+
;
; :DESCRIPTION:
;
;   
;
;-
pro stx_bitStreamRW__test::test_writeread_memory
  
  
  bw = obj_new('stx_bitstream_writer', size=1000)
  
  td = *(self.testdata)
  
  foreach data, td do begin
    bw->write, data.data, bits= data.bits
  endforeach
  
  pos_writer = bw->getbitposition()
  
  totalbits = long(total(td.bits, /double))
  
  assert_equals, pos_writer, totalbits 

  
  br = obj_new('stx_bitstream_reader',stream=bw->getBuffer(/trim))
  
  foreach data, td do begin
    read_data = br->read(data.type, bits=data.bits)
     assert_equals, read_data, data.data 
  endforeach  
  
  pos_reader = br->getbitposition()
  assert_equals, pos_reader, totalbits
  
  
end


pro stx_bitstreamrw__test::test_writeread_random_file
 
  n_data  = 1000000L
  word_length = 10

 

 
  data = byte(randomu(1,n_data,/ulong))
  
;   bw = obj_new('stx_bitstream_writer', size=(n_data*2*word_length), filename="test_writeread_random_file.bin")
;  
;  bw->write,data, bits=word_length, /extract   
;    
;  pos_writer = bw->getbitposition()
;
  totalbits = n_data * word_length
;
;  assert_equals, pos_writer, totalbits
;  
;  destroy, bw

  br = obj_new('stx_bitstream_reader',   filename="test_writeread_random_file.bin")

  for i=0, n_data-1 do begin
    read_data = br->read(1,  bits=word_length)
    assert_equals, read_data, data[i]
  end
  
  pos_reader = br->getbitposition()
  assert_equals, pos_reader, totalbits

end

pro stx_bitstreamrw__test::test_writeread_file


  bw = obj_new('stx_bitstream_writer', size=1000,filename="test_writeread_file.bin" )

  td = *(self.testdata)

  foreach data, td do begin
    bw->write, data.data, bits= data.bits
  endforeach

  pos_writer = bw->getbitposition()

  totalbits = long(total(td.bits, /double))

  assert_equals, pos_writer, totalbits
  
  destroy, bw
    
  br = obj_new('stx_bitstream_reader', filename="test_writeread_file.bin")

  foreach data, td, idx do begin
    read_data = br->read(data.type, bits=data.bits)
    print, idx, read_data, data.data
    assert_equals, read_data, data.data
  endforeach

  pos_reader = br->getbitposition()
  assert_equals, pos_reader, totalbits

  destroy, br
end


pro stx_bitStreamRW__test__define
  compile_opt idl2, hidden

  void = { $
    stx_bitStreamRW__test, $
    testdata : ptr_new(), $
    inherits iut_test }
end
