; gets all data products out of fsw and ivs and retruns a HASH for the TMTC writer

function stx_telemetry_util_fsw2tmtc, fsw=fsw, ivs=ivs

  bulk_data = HASH()
  
  if n_elements(fsw) gt 0 then begin
    ;ql_lightcurve
    fsw->getproperty, STX_FSW_M_LIGHTCURVE=ql_lightcurve, /COMPLETE, /comb
  
    ;ql_flare_flag_location
    fsw->getproperty, STX_FSW_M_FLARE_FLAG=STX_FSW_M_FLARE_FLAG, $
      STX_FSW_M_COARSE_FLARE_LOCATION=STX_FSW_M_COARSE_FLARE_LOCATION, $
      /COMPLETE, /comb
  
    ;ql_variance
    fsw->getproperty, STX_FSW_M_VARIANCE=stx_fsw_m_variance, /COMPLETE, /comb
  
    ;ql_spectra
    ;fsw->getproperty,STX_FSW_QL_SPECTRA=stx_fsw_ql_spectra,STX_FSW_QL_LT_SPECTRA=stx_fsw_ql_lt_spectra  , /complete, /comb
    ql_spectra=fsw->getdata(output_target='stx_fsw_ql_spectra')
  
    ;ql_background_monitor
    fsw->getproperty, STX_FSW_M_BACKGROUND=ql_background_monitor, /comb, /comp
  
    ;ql_calibration_spectrum
    fsw->getproperty, STX_FSW_M_CALIBRATION_SPECTRUM=stx_fsw_m_calibration_spectrum, /comb, /comp
    
    bulk_data['ql_lightcurve']=ql_lightcurve
    bulk_data['ql_flare_location']=stx_fsw_m_coarse_flare_location
    bulk_data['ql_flare_flag']=stx_fsw_m_flare_flag
    bulk_data['ql_variance']=stx_fsw_m_variance
    bulk_data['ql_spectra']=ql_spectra
    bulk_data['ql_background_monitor']=ql_background_monitor
    bulk_data['ql_calibration_spectrum']=stx_fsw_m_calibration_spectrum
    
    
  endif
  
  if n_elements(ivs) gt 0 then begin
    ; science data
    l0 = ivs.L0_ARCHIVE_BUFFER_GROUPED
    l1 = ivs.L1_IMG_COMBINED_ARCHIVE_BUFFER_GROUPED
    l2 = ivs.L2_IMG_COMBINED_PIXEL_SUMS_GROUPED
    l1_spc = ivs.L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED
    l3 = ivs.L3_IMG_COMBINED_VISIBILITY_GROUPED
    
    bulk_data['sd_xray_0']=l0
    bulk_data['sd_xray_1']=l1
    bulk_data['sd_xray_2']=l2
    bulk_data['sd_xray_3']=l3
    bulk_data['sd_spc']=l1_spc
  endif
    
  return, bulk_data

end