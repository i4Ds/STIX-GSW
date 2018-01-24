function stx_fsw_ivs_spectrogram, counts, time_axis, energy_edges = energy_edges

default, energy_edges, indgen(33,/BYTE)

str = { type         : 'stx_fsw_ivs_spectrogram', $
        counts       : ULONG64(counts), $
        time_axis    : time_axis, $
        energy_axis  : stx_construct_energy_axis(select = energy_edges) $
      }

return, str

end