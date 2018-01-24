;+
; :description:
;    This procedure reads the detecor number, pixel number, gain and offset from a given csv file
;    and returns the values in a stx_gain_offset structure
;
; :categories:
;    simulation
;
; :params:
; 
;    filename : in, required, type="string"
;             the filename of the gain offset csv file
;             
; :keywords:
;    directory : type = string, location of the offset_gain_table csv file
;    reset: boolean, if set, reread the offset_gain_table csv file
; :examples:
;  og_struct =  stx_offset_gain_reader( 'offset_gain_table.csv')
;
; :history:
;    30-jun-2015 - ECMD (Graz), initial release
;    02-jul-2015 - richard.schwartz@nasa.gov - added default filename
;
;-
function stx_offset_gain_reader, filename, directory = directory, reset = reset

  default, directory , getenv('STX_DET')
  default, filename, 'offset_gain_table.csv'
  default, reset, 0
  common stx_offset_gain_reader, full_filename, og_str
  default, full_filename, 'dummy_filename_xxx'
  reset = stregex( /boo, /fold, file_basename( filename ), file_basename( full_filename )) ? reset : 1 
  if ~is_struct( og_str ) or reset then begin
    filename = form_filename( filename, '.csv' )
    full_filename = loc_file( path = directory, filename, count = nfile )
    if nfile eq 0 then message,'offset gain table file not found '
    
    csv_str = read_csv(full_filename, header = header)
    
    n_detpix = n_elements(csv_str.(1))
    
    og_str  = replicate( stx_offsetgain(), n_detpix )
    
  
    expected_header = ['detector_number', 'pixel_number', 'offset', 'gain']
    
    mes = 'Column headers in csv file must match expected names for stx_offsetgain structure'
    assert_equals, expected_header, header, mes
    
    for tag_idx = 0L, n_elements(header)-1 do begin
      og_str.(tag_idx+1)  = csv_str.(tag_idx)
    endfor
    endif
  
  return, og_str
end