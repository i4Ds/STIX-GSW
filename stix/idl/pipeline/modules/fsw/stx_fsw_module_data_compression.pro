;+
; :description:
;    Create a new STX_FSW_MODULE_DATA_COMPRESSION object
;
; returns the new module
;-
function stx_fsw_module_data_compression
  return , obj_new('stx_fsw_module_data_compression','stx_fsw_module_data_compression', $
      ['stx_fsw_archive_buffer*', 'STX_FSW_TRIGGERS*',  'stx_fsw_m_rate_control_regime', 'stx_fsw_m_coarse_flare_locator', 'stx_fsw_ivs_interval*', 'stx_fsw_ivs_interval*', 'stx_fsw_m_detector_monitor',  'stx_time',   'stx_time',     'stx_time',   'double*',              'long64*',            'ulong*'], $
      ['archive_buffer',          'triggers',           'rcr',                           'cfl',                            'ivs_intervals_img',     'ivs_intervals_spc',     'detector_monitor',            'start_time', 'flare_start',  'flare_end',  'archive_buffer_times', 'count_spectrogram',  'pixel_count_spectrogram'])
end
