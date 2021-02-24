function stx_spectrogram_livetime,  spectrogram, corrected_counts =corrected_counts, level = level
  ;convert the triggers to livetime

default, level, 1

  ntimes = n_elements(spectrogram.time_axis.time_start)
  nenergies = (spectrogram.counts.dim)[0]
  det_used = where(spectrogram.detector_mask eq 1, ndet)


  case level of
    1: begin
      dim_counts = [nenergies, ndet, ntimes]
      triggergram = stx_triggergram(transpose( spectrogram.trigger ),  spectrogram.time_axis)
      livetime_fraction = stx_livetime_fraction(triggergram, det_used)

      livetime_fraction = transpose( rebin(reform(livetime_fraction, ndet, ntimes),[dim_counts[1:2],dim_counts[0]]),[2,0,1])

    end
    4:begin
      dim_counts = [nenergies, ntimes]
      trig = (fltarr(16)+1./16.)##spectrogram.trigger
      triggergram = stx_triggergram(transpose(trig),  spectrogram.time_axis)
      livetime_fraction = stx_livetime_fraction(triggergram, det_used)
      livetime_fraction = transpose( rebin(reform(livetime_fraction),[dim_counts[1],dim_counts[0]]))

    end

    else: message, 'Currently supported levels are 1 (pixel data) and 4 (spectrogram)'
  endcase

  corrected_counts =  spectrogram.counts/livetime_fraction


  return, livetime_fraction

end