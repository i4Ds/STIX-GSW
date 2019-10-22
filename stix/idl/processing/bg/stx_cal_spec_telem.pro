;+
; :Description:
;    This procedure manages the simulation of processing a spectrum through
;    configuration (some at full res, some at grouped res), compression and decompression
;    This routine is used exclusively by stx_bkg_sim_demo and should not be modified
;    unless it is thoroughly understood
;
; :Params:
;    back_str - input spectrogram MC simulation
;    configuration_struct - describes the grouping parameters
;    spectrogram - returned spectrogram structure
;
;
;
; :Author: rschwartz70@gmail.com, 3-may-2018
;-
pro stx_cal_spec_telem, back_str, configuration_struct, spectrogram

  
  stx_bkg_sim_bld_subspectra, back_str.data, back_str.e_axis.edges_2, configuration_struct

  stx_bkg_sim_rcvr_subspectra, configuration_struct, recovered_from_telem
  ndata = n_elements(back_str.data)
  data = reform( recovered_from_telem[ 0: ndata-1 ], ndata, 1)
  
  sp = stx_spectrogram( data, back_str.t_axis, back_str.e_axis, $
    reform( avg( back_str.ltime )+ data*0.0, ndata, 1) )
  spectrogram = rep_tag_value( sp, double(sp.data),'data')
end
