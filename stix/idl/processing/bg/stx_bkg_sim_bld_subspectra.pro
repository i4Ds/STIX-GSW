;
;+
; :Description:
;    This routine applies the extracts a subspectrum and then puts it into a form
;    for telemetry upload which it includes within the configuration structure
;
; :Params:
;    background_sim - 1024 bin model background spectrum
;    edg2
;    configuration_struct
;
;
;
; :Author: richard.schwartz@nasa.gov, 21-jul-2016
;-
pro  stx_bkg_sim_bld_subspectra, background_sim, edg2, configuration_struct

bkg = background_sim
;bkg is the calibration spectrum using the 4096 to 1024 compression

nconf = n_elements(configuration_struct) ;number of subspectra configuratin structures
;function stx_km_compress, data, k, m, s, error = error

for i = 0, nconf-1 do begin
  cnf = configuration_struct[i]
  uncompressed = bkg[ cnf.ichan_lo: cnf.ichan_lo + cnf.npoints * cnf.ngroup -1]
  grouped = rebin( uncompressed, cnf.npoints ) * cnf.ngroup
  cnf.subspec_orig = ptr_new( uncompressed )
  cnf.subspec_grouped  = ptr_new( grouped )
  cnf.subspec_c = ptr_new( stx_km_compress( fix(grouped), cnf.cmp_k, cnf.cmp_m, cnf.cmp_s))
  configuration_struct[i] = cnf
endfor
end
