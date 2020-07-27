function stx_convert_fsw_ql_spectra_to_asw, ql_spectra
 
   
  times = ql_spectra.samples[uniq(ql_spectra.samples.delta_time)].delta_time
  
  times = times[sort(times)]
  
  time_axis = stx_construct_time_axis(stx_time_add(ql_spectra.start_time, seconds = [times,  times[-1] + ql_spectra.INTEGRATION_TIME] ))
  
  
  stx_asw_spectra = stx_construct_asw_ql_spectra(time_axis = time_axis,pixel_mask=ql_spectra.pixel_mask )
  
  
  foreach time, times, idx do begin

    detectors_samples = ql_spectra.samples[where(ql_spectra.samples.delta_time eq time)]
    stx_asw_spectra.DETECTOR_MASK[detectors_samples.detector_index,idx]=1
   
    stx_asw_spectra.spectrum[*,detectors_samples.detector_index,idx] = detectors_samples.counts
    stx_asw_spectra.TRIGGERS[detectors_samples.detector_index,idx] = detectors_samples.trigger
    
  endforeach
    
 return, stx_asw_spectra
 

end