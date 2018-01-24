list =  stx_fsw_rhessi_spectrogram2ordered_detector_eventlist(obs_time = hsi_flare2time(2022003)-[0.,80.],/plotting,photoncount=200000L, dist_out=dist_out)
energy =  list.detector_events.energy_ad_channel
energy = energy[sort(energy)]

window, 7
plot, total(dist_out,1), psym=10
oplot, total(dist_out,1), linestyle=5

window, 5
his = histogram(energy, binsize=1,locations=loc)
plot, loc, his, xrange=[120,300], /xstyle



