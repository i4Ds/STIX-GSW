;+
; :description:
;    Create a new STX_FSW_MODULE_INTERVALSELECTION object
;
; returns the new module
;-
function stx_fsw_module_intervalselection  
  ivs = obj_new('stx_fsw_module_intervalselection','stx_fsw_module_intervalselection', $
                ['stx_fsw_archive_buffer*', 'stx_time',   'byte*',  'stx_time_axis', 'byte*',            'double*',     'stx_energy_axis'], $
                ['archive_buffer',          'start_time', 'rcr',    'rcr_time_axis', 'active_detectors', 'background', 'background_energy_axis'])
  
  return, ivs
end

  