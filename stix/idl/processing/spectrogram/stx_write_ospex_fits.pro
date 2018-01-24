;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_write_ospex_fits
;
; :purpose:
;       Write spectrum and corresponding DRM FITS files from input STIX regular spectrogram data.
;
;
; :category:
;       helper methods
;
; :description:
;       Routine to write a spectrum FITS file from stix spectrogram data. Based on the routine hsi_spectrum__fitswrite.
;
; :keywords:
;
;       spectrum - spectrogram structure
;
;       specfilename -  file name for spectrum fits
;
;       srmfilename – file name for srm fits
;
;       srmdata - spectral response matrix array
;
;       ph_edges  - photon edges for srm if array has not been supplied
;
;       _extra - extra keys
;
;
;
; :calling sequence:
;       IDL> stx_write_opsex_fits, spectrum = spec, srm = srm
;
;
; :history:
;       23-Sep-2014 – ECMD (Graz), initial release
;       12-Dec-2014 – ECMD (Graz), fixed dimensions to agree with new standard index order of count(energy, pixel, detector, time)
;                                  Now using rate rather than counts as the data units
;       26-nov-2017 - RAS   (GSFC), Get ph_edges from srm structure if passed
;-


pro stx_write_ospex_fits, $
    spectrum = spec, $
    specfilename = specfilename, $
    srmfilename = srmfilename, $
    srmdata = srm, $
    ph_edges = ph_edges, $
    _extra = extra_keys
    
    
  data = float(spec.data)
  utime = stx_time2any( spec.t_axis.time_start )
  ct_edges = spec.e_axis.edges_1
  edge_products, ct_edges, edges_2 = ct_edges_2 ;if the energy edges are changed this won't be needed
  livetime =  spec.ltime
  nchan = n_elements( ct_edges ) - 1
  
  
  duration=spec.t_axis.duration
  duration_array=rebin(duration,n_elements(duration),n_elements(ct_edges)-1)
  data=f_div(data,transpose(duration_array))
  
  
  ;get default filenames for the spectrum and srm files
  default, specfilename, 'stx_spectrum_' + time2file( utime[0] ) + '.fits'
  default, srmfilename, 'stx_srm_' + time2file( utime[0] ) + '.fits'
  
  ;energy edges extended in photon space
  maxct = max( ct_edges )
  default, ph_edges, [ ct_edges, maxct + maxct*(findgen(10)+1)/10. ]
  
  ;if there is no input drm a standard stix drm is made using the count and energy edges
  if ~keyword_set(srm) then begin
    srm = stx_build_drm( ct_edges, ph_energy_edges = ph_edges )
  endif else if is_struct( srm ) then ph_edges = get_tag_value( srm, /edges_in) 
  edge_products, ph_edges, edges_2 = ph_edges_2
  
  ;extract drm matrix and area from the drm structure
  smatrix = srm.smatrix
  area = srm.area
  
  ;calculate the start and end times in the format used for the RHESSI fits
  mjd = stx_time2any( [ spec.t_axis.time_start[0], spec.t_axis.time_end[ n_elements( spec.t_axis.time_end ) - 1 ] ], /mjd )
  timezeri = mjd[0].mjd
  tstartf = double( mjd[0].time )/8.64d7
  timezerf = 0.0
  tstopi = mjd[1].mjd
  tstopf = double( mjd[1].time )/8.64d7
  
  ;reformat time axis
  tedges2=transpose( [ [ stx_time2any(spec.t_axis.time_start) ], [ stx_time2any( spec.t_axis.time_end ) ] ] )
  ut = stx_time2any( tedges2 , /mjd )
  ut = ( ut.time/1000.0d ) + ( ut.mjd - timezeri )*86400.0d
  
  ;calculate time parameters to be passed into the fits file
  specnum = indgen( n_elements( ut[0,*] ) ) + 1
  channel = rebin( lindgen( nchan ), nchan, n_elements( ut[0,*] ) )
  timedel = float( reform( ut[1,*] - ut[0,*] ) )
  timecen = double( reform( ut[0,*] + timedel/2.0 ) )
  exposure = total( timedel*livetime )
  
  
  
  Units = 'rate'
  ;make the standard fits headers for the spectrum and srm files
  stx_make_spectrum_header,specfile = specfilename, $
    srmfile = srmfilename, $
    ratearea = area, $
    srmarea = area, $
    rcr_state = rcr_state, $
    primary_header = primary_header, $
    specheader = specheader, $
    specparheader = specparheader, $
    srmheader = srmheader, $
    srmparheader = srmparheader, $
    units = units, $
    energy_band = ct_edges_2
    
    
  units_arr = [ units, units, ' ', ' ', ' ', 's', 's' ]
  
  ;make the rate structure
  rate_struct = stx_rate_header( nchan = nchan, exposure = exposure, timezeri = timezeri, tstartf = tstartf, $
    tstopi = tstopi, tstopf = tstopf )
    
    
  ;make the spectrum file
  spectrum2fits, specfilename, rate_struct = rate_struct, write_primary_header = 1, $
    primary_header = primary_header, extension_header = specheader, $
    data = data, error = data_error, $
    units = units_array, spec_num = specnum, channel = channel, $
    timedel = timedel, $
    timecen = timecen, $
    nrows = n_elements( timecen ),$
    livetime = livetime, numband = nchan, minchan = lindgen(nchan), $
    maxchan = lindgen(nchan) + 1, $
    e_min = reform( ct_edges_2[0,*] ), $
    e_max = reform( ct_edges_2[1,*] ), e_unit = 'kev', $
    err_code = err_code, _extra = extra_keys, err_msg = err_msg
    
  ;make the srm fits file
  rm2fits, srmfilename, ph_edges_2, smatrix, $
    write_primary_header = 1, $
    primary_header = primary_header, $
    extension_header = srmheader, minchannel = 0l, $
    maxchannel = nchan-1l, det_channels = ct_edges_2, $
    e_unit = 'kev', multidetector = 0, $
    rmf_header = rmf_header, $
    chantype = rate_struct.chantype, $
    err_code = err_code, err_msg = err_msg, $
    _extra = extra_keys
    
end
