;+
; :FILE_COMMENTS:
;    This module is part of the flight software (FSW) package and
;    generates a tmtc dump to stream or file
;
; :CATEGORIES:
;    flight software, tmtc, writing , module
;
; :EXAMPLES:
;    obj = stx_fsw_module_tmtc()
;
; :HISTORY:
;    22-Nov-2016 - Nicky Hochmuth (FHNW), initial release
;-

;+
; :DESCRIPTION:
;    This internal routine is dumping "all" data to tmtc
;
; :PARAMS:
;    in : in, required, type="defined in 'factory function'"
;        this is a STX_FSW_QL_... object
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :RETURNS:
;   this function returns an array of the variance
;
; :HISTORY:
;   26-jun-2014 - Nicky Hochmuth (FHNW), initial release
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), updated QL spectra TM generation to work with new structure
;   27-Mar-2017 - Shane Maloney (TCD), fixed bug where incorrect strucure was used if flare time was overridden
;-

function stx_fsw_module_tmtc::_execute, in, configuration
  compile_opt hidden

  conf = *configuration->get(module=self.module)
  
  filename = in.filename eq "" ? !NULL : in.filename
  
  
  fsw = in.fsw
  
  fsw->getproperty, current_bin=current_bin
  
  if current_bin lt 0 then return, !NULL
  
  
  ;Create TMTC writer object
  tmtc_writer = stx_telemetry_writer(filename=filename, size=2L^24)
  solo_packets = hash()
  
  if (in.ql_variance) then begin
    fsw->getproperty, STX_FSW_M_VARIANCE=stx_fsw_m_variance, /COMPLETE, /comb
    tmtc_writer->setdata, ql_variance=stx_fsw_m_variance, $
      compression_param_s = conf.ql_variance_spectrum_compression_counts[0], $
      compression_param_k = conf.ql_variance_spectrum_compression_counts[1], $
      compression_param_m = conf.ql_variance_spectrum_compression_counts[2]

  endif
  
  if (in.ql_spectra) then begin
    ql_spectra=fsw->getdata(output_target='stx_fsw_ql_spectra')
    tmtc_writer->setdata, ql_spectra=ql_spectra, $
      compression_param_s_sp = conf.ql_spectra_compression_counts[0], $
      compression_param_k_sp = conf.ql_spectra_compression_counts[1], $
      compression_param_m_sp = conf.ql_spectra_compression_counts[2], $
      compression_param_s_t = conf.ql_spectra_compression_triggers[0], $
      compression_param_k_t = conf.ql_spectra_compression_triggers[1], $
      compression_param_m_t = conf.ql_spectra_compression_triggers[2]
  endif

  if (in.ql_flare_flag_location) then begin
    fsw->getproperty, STX_FSW_M_FLARE_FLAG=STX_FSW_M_FLARE_FLAG, STX_FSW_M_COARSE_FLARE_LOCATION=STX_FSW_M_COARSE_FLARE_LOCATION, /COMPLETE, /comb
    tmtc_writer->setdata, ql_flare_location=stx_fsw_m_coarse_flare_location, ql_flare_flag=stx_fsw_m_flare_flag, solo_packets= solo_packets
  endif

  if (in.ql_calibration_spectrum) then begin
    fsw->getproperty, STX_FSW_M_CALIBRATION_SPECTRUM=stx_fsw_m_calibration_spectrum, /comb, /comp
    tmtc_writer->setdata, ql_calibration_spectrum=stx_fsw_m_calibration_spectrum, solo_packets= solo_packets, $
      compression_param_s = conf.ql_calibration_spectrum_compression_counts[0], $
      compression_param_k = conf.ql_calibration_spectrum_compression_counts[1], $
      compression_param_m = conf.ql_calibration_spectrum_compression_counts[2], subspectra_definition=conf.calibration_subspectra
  endif

  if (in.ql_light_curves) then begin
    fsw->getproperty, stx_fsw_m_lightcurve=ql_lightcurve, /COMPLETE, /comb

    tmtc_writer->setdata, ql_lightcurve=ql_lightcurve, solo_packets=solo_packets, $
      compression_param_s_acc = conf.ql_light_curves_compression_counts[0], $
      compression_param_k_acc = conf.ql_light_curves_compression_counts[1], $
      compression_param_m_acc = conf.ql_light_curves_compression_counts[2], $
      compression_param_s_t = conf.ql_light_curves_compression_triggers[0], $
      compression_param_k_t = conf.ql_light_curves_compression_triggers[1], $
      compression_param_m_t = conf.ql_light_curves_compression_triggers[2]

  endif
  
  if (in.ql_background_monitor and current_bin gt 8) then begin
    fsw->getproperty, stx_fsw_m_background=stx_fsw_m_background, /comb, /comp
    tmtc_writer->setdata, ql_background_monitor=stx_fsw_m_background, solo_packets= solo_packets, $
      compression_param_s_bg = conf.ql_background_compression_counts[0], $
      compression_param_k_bg = conf.ql_background_compression_counts[1], $
      compression_param_m_bg = conf.ql_background_compression_counts[2], $
      compression_param_s_t = conf.ql_background_compression_triggers[0], $
      compression_param_k_t = conf.ql_background_compression_triggers[1], $
      compression_param_m_t = conf.ql_background_compression_triggers[2]
  endif
  
  
  if in.sd_xray_0 OR in.sd_xray_1 OR in.sd_xray_2 OR in.sd_xray_3 OR in.sd_spectrogram then begin
  
    if tag_exist(in, "rel_flare_time", /quiet ) then begin
       
       fsw->getproperty, reference_time=reference_time
        
       flare_times = stx_fsw_flare_list_entry(fstart=stx_time_add(reference_time,seconds=in.rel_flare_time[0]), fend=stx_time_add(reference_time,seconds=in.rel_flare_time[1]), fsbyte=1, ended=1b)

;     10-Oct-2017 ECMD  - input expected by fsw->getdata(output_target="stx_fsw_ivs_result") is "stx_fsw_flare_list_entry"
      
    endif else FLARE_TIMES = fsw->getdata(output_target='stx_fsw_flare_selection_result')
    
    foreach flare, FLARE_TIMES do begin
      
      if ~flare.ended then continue 
      
      ;run the interval selection for the given flare time
      ivs_result = fsw->getdata(output_target="stx_fsw_ivs_result", input_data=flare)
  
      ; science data
      AB = ivs_result.l0_archive_buffer_grouped
      ivs_pixel_data = ivs_result.l1_img_combined_archive_buffer_grouped
      ivs_summed_pixel_data = ivs_result.l2_img_combined_pixel_sums_grouped
      visibility = ivs_result.L3_IMG_COMBINED_VISIBILITY_GROUPED
      sd_spc = ivs_result.l1_spc_combined_archive_buffer_grouped
  
      if in.sd_xray_0 then tmtc_writer->setdata, sd_xray_0 = AB, solo_packets= solo_packets, $
        compression_param_s_acc = conf.sd_xray_0_compression_counts[0], $
        compression_param_k_acc = conf.sd_xray_0_compression_counts[1], $
        compression_param_m_acc = conf.sd_xray_0_compression_counts[2], $
        compression_param_s_t = conf.sd_xray_0_compression_triggers[0], $
        compression_param_k_t = conf.sd_xray_0_compression_triggers[1], $
        compression_param_m_t = conf.sd_xray_0_compression_triggers[2]
        
      if in.sd_xray_1 then tmtc_writer->setdata, sd_xray_1 = ivs_pixel_data, solo_packets= solo_packets,$ 
        compression_param_s_acc = conf.sd_xray_1_compression_counts[0], $
        compression_param_k_acc = conf.sd_xray_1_compression_counts[1], $
        compression_param_m_acc = conf.sd_xray_1_compression_counts[2], $
        compression_param_s_t = conf.sd_xray_1_compression_triggers[0], $
        compression_param_k_t = conf.sd_xray_1_compression_triggers[1], $
        compression_param_m_t = conf.sd_xray_1_compression_triggers[2]
        
      if in.sd_xray_2 then tmtc_writer->setdata, sd_xray_2 = ivs_summed_pixel_data, solo_packets= solo_packets, $
        compression_param_s_acc = conf.sd_xray_2_compression_counts[0], $
        compression_param_k_acc = conf.sd_xray_2_compression_counts[1], $
        compression_param_m_acc = conf.sd_xray_2_compression_counts[2], $
        compression_param_s_t = conf.sd_xray_2_compression_triggers[0], $
        compression_param_k_t = conf.sd_xray_2_compression_triggers[1], $
        compression_param_m_t = conf.sd_xray_2_compression_triggers[2]
      
      if in.sd_xray_3 then tmtc_writer->setdata, sd_xray_3 = visibility, solo_packets= solo_packets, $
        compression_param_k_acc  = conf.sd_xray_3_compression_totalflux[0], $
        compression_param_m_acc  = conf.sd_xray_3_compression_totalflux[1], $
        compression_param_s_acc  = conf.sd_xray_3_compression_totalflux[2], $
        compression_param_k_t     = conf.sd_xray_3_compression_triggers[0], $
        compression_param_m_t     = conf.sd_xray_3_compression_triggers[1], $
        compression_param_s_t     = conf.sd_xray_3_compression_triggers[2], $
        compression_param_k_vis   = conf.sd_xray_3_compression_vis[0], $
        compression_param_m_vis   = conf.sd_xray_3_compression_vis[1], $
        compression_param_s_vis   = conf.sd_xray_3_compression_vis[2]
            
      if in.sd_spectrogram then tmtc_writer->setdata, sd_spc = sd_spc, solo_packets= solo_packets, $
        compression_param_s_acc = conf.sd_spectrogram_compression_counts[0], $
        compression_param_k_acc = conf.sd_spectrogram_compression_counts[1], $
        compression_param_m_acc = conf.sd_spectrogram_compression_counts[2], $
        compression_param_s_t = conf.sd_spectrogram_compression_triggers[0], $
        compression_param_k_t = conf.sd_spectrogram_compression_triggers[1], $
        compression_param_m_t = conf.sd_spectrogram_compression_triggers[2]
  
  
    endforeach
 endif
    
  
  out_data = isa(filename) ? filename : tmtc_writer->getBuffer(/trim)
  
  destroy, tmtc_writer 
  
  
  
  return, { $
    data : out_data, $
    solo_packets : solo_packets $ 
  }
end

;+
; :DESCRIPTION:
;    Constructor
;
; :INHERITS:
;    hsp_module
;
; :HIDDEN:
;-
pro stx_fsw_module_tmtc__define
  compile_opt idl2, hidden

  void = { stx_fsw_module_tmtc, $
    inherits ppl_module }
end
