pro  stx_bkg_sim_rcvr_subspectra, config, bkg

;bkg is the calibration spectrum using the 4096 to 1024 compression

nconf = n_elements(config) ;number of subspectra configuratin structures
;function stx_km_compress, data, k, m, s, error = error
bkg = fltarr( 1024 )
for i = 0, nconf-1 do begin
  subspec_grouped = stx_km_decompress( *config[i].subspec_c, config[i].cmp_k, config[i].cmp_m, config[i].cmp_s)
  ;Note that the grouping is recovered by using /sample with rebin
  ungrouped = rebin( subspec_grouped, config[i].npoints  * config[i].ngroup, /sample ) / config[i].ngroup
  config[i].subspec_rcvr = ptr_new( ungrouped )
  bkg[ config[i].ichan_lo: config[i].ichan_lo + config[i].npoints * config[i].ngroup -1 ] = ungrouped
endfor
end
