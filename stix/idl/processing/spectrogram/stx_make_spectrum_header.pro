;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_make_spectrum_header
;
; :purpose:
;
;       Makes spectrum and srm headers for stix spectrum fits files.
;
; ;category:
;
;       helper methods
;
; :description:
;   Routine to make the headers for stix spectrum fits files based on hsi_spectrum__fits_headers.
;
;
; :keywords:
;
;    specfile - specfile
;
;    srmfile - srmfile
;
;    ratearea - ratearea
;
;    srmarea - srmarea
;
;    sum_flag - sum_flag
;
;    coincidence_flag - coincidence_flag
;
;    sum_coincidence - sum_coincidence
;
;    sep_dets - sep_dets
;
;    rcr_state - rate control regime state
;
;    primary_header - primary_header
;
;    specheader - specheader
;
;    specparheader - specparheader
;
;    srmheader - srmheader
;
;    srmparheader - srmparheader
;
;    units  - units
;
;    energy_band - energy_band
;
;
;
; :returns:
;    Returns the spectrum and drm headers for stix spectrum fits files
;
;
; :calling sequence:
;
;    IDL> stx_make_spectrum_header,specfile = specfilename, srmfile = srmfilename,  ratearea = area,  srmarea = area, $
;    atten_state = atten_state, primary_header = primary_header, specheader = specheader,  specparheader = specparheader, $
;    srmheader = srmheader, srmparheader = srmparheader, units = units, energy_band = ct_edges_2
;
;
; :history:
;       23-Sep-2014 – ECMD (Graz), initial release;
;       03-Dec-2018 – ECMD (Graz), Changed RCR to FILTER for OSPEX compatibility  
;       23-Feb-2022 - ECMD (Graz), added information of xspec compatibility and time shift to file headers 
;       
;-

pro stx_make_spectrum_header,specfile = specfile, $
  srmfile = srmfile, $
  ratearea = ratearea, $
  srmarea = srmarea, $
  sum_flag = sum_flag, $
  coincidence_flag = coincidence_flag, $
  sum_coincidence = sum_coincidence, $
  sep_dets = sep_dets, $
  rcr_state = rcr_state, $
  primary_header = primary_header, $
  specheader = specheader, $
  specparheader = specparheader, $
  srmheader = srmheader, $
  srmparheader = srmparheader, $
  units = units, $
  energy_band = energy_band, $
  time_shift = time_shift,$
  compatibility = compatibility,$
  any_specfile = any_specfile

  fxhmake, header, /date, /init, /extend, errmsg = errmsg

  currtime = strmid(anytim(!stime, /ccsds), 0, 19)
  fxaddpar, header, 'DATE', currtime, 'File creation date (YYYY-MM-DDThh:mm:ss UTC)'
  fxaddpar, header, 'ORIGIN', 'STIX', $
    'Spectrometer Telescope for Imaging X-rays'
  observer = getenv( 'USER' )
  if observer eq '' then observer = 'Unknown'
  fxaddpar, header, 'OBSERVER', observer, $
    'Usually the name of the user who generated file'
  fxaddpar, header, 'TELESCOP', 'Solar Orbiter', 'Name of the Telescope or Mission'
  fxaddpar, header, 'INSTRUME', 'STIX', 'Name of the instrument'
  fxaddpar, header, 'OBJECT', 'Sun', 'Object being observed'


  fxaddpar, header, 'TIME_UNIT', 1
  fxaddpar, header, 'ENERGY_L', min( energy_band )
  fxaddpar, header, 'ENERGY_H', max( energy_band )

  ; acs changed 2005-08-17. Needs a standard date format. Also timeunit
  ; was wrong it was d and not s
  timesys = strmid(anytim('00:00 1-Jan-79', /ccsds), 0, 19)
  fxaddpar, header, 'TIMESYS',  timesys, 'Reference time in YYYY MM DD hh:mm:ss'
  fxaddpar, header, 'TIMEUNIT', 'd', 'Unit for TIMEZERO, TSTARTI and TSTOPI'
  fxaddpar, header, 'TIME_SHIFT', time_shift, 'Applied correction for Earth-SO light travel time'


  primary_header = header

  specheader = primary_header[1:*]
  specheader = specheader[ where(strmid(specheader,0,6) ne 'EXTEND') ]

  fxaddpar, specheader, 'GEOAREA', ratearea
  fxaddpar, specheader, 'DETUSED', 1
  fxaddpar, specheader, 'SUMFLAG', 0, 'no sum flag'
  fxaddpar, specheader, 'SUMCOINC', 0, 'no sum coinc'
  fxaddpar, specheader, 'COINCIDE', 0, 'no coinc'

  fxbhmake, specparheader, 1
  specparheader = $
    merge_fits_hdrs( specparheader, specheader, ERR_MSG=err_msg, $
    ERR_CODE=err_code )
    
  expected_instrument = keyword_set(any_specfile) ? 'STIX' :'HESSI'
  fxaddpar, specparheader, 'EXTNAME', expected_instrument +' Spectral Object Parameters', 'Extension name'

  srmheader = specheader
  fxaddpar, srmheader, 'GEOAREA', ratearea
  fxaddpar, specheader, 'RESPFILE', srmfile
  fxaddpar, srmheader, 'PHAFILE', specfile
  fxaddpar, srmheader,  'SOFTWARE_COMPATIBILITY', compatibility

  sep_dets = 0
  sep_dets_cmt = sep_dets ? $
    'Separate response matrices' : $
    'Sum of response matrices'
  fxaddpar, srmheader, 'SEPDETS', sep_dets, sep_dets_cmt

  if exist(rcr_state) then fxaddpar, srmheader, 'FILTER', fix(rcr_state), 'Attenuator state'

  fxbhmake, srmparheader, 1
  srmparheader = merge_fits_hdrs( srmparheader, srmheader, $
    err_msg=err_msg, err_code=err_code )


  fxaddpar, srmparheader, 'EXTNAME', 'SRM Object Parameters'

  fxaddpar, specheader, 'COMMENT', 'absTime[i] = mjd2any(MJDREF + TIMEZERO) + TIME[i]'


end
