;+
; :DESCRIPTION:
;    Create a new STX_FSW_MODULE_DATA_COMPRESSION object
;
; returns the new module
;-
function stx_fsw_module_reduce_ql_spectra
  return , obj_new('stx_fsw_module_reduce_ql_spectra','stx_fsw_module_reduce_ql_spectra', $
    ['stx_fsw_m_rate_control_regime', 'stx_fsw_ql_spectra', 'stx_fsw_ql_spectra_lt'], $
    ['rcr',                           'spectra',            'spectra_lt'])
end
