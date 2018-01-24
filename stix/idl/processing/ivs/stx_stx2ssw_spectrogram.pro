function stx_stx2ssw_spectrogram, stx_spectrogram

  return, make_spectrogram(stx_spectrogram.data,time_axis=stx_spectrogram.t_axis.time,spectrum_axis=stx_spectrogram.e_axis.mean)
end