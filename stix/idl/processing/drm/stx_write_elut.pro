;+
; :Description:
;    Using the measured gain (adc or adc1024) gain and offset
;    write the ELUT (Energy LookUp Table) into a CSV file for all 384 STIX pixel/detectors
;    adc1024 bins are the adc (4096 channels) with two LSBs suppressed
;    An ADC1024 edge is computed from round( 4 * offset1024 + Edge_in_keV * ( gain1024 / 4 ) )
;
; :Params:
;    gain   - adc1024 bin width in keV, nominally about 0.4
;    offset - adc1024 edge corresponding to 0.0 keV
;
; :Keywords:
;    h5    - if passed, matlab fitresults.mat file holding the gain and offset
;    scale - default is 4, using the fitted values from the calibration spectra on the 1024 compressed spectra
;    If based on the 4096 adc channels, then scale should be 1
;    path  - directory path to h5 file
;    starlet - produce an ELUT csv filr directly compatible with starlet software
;    
; :Results:
;   Writes an ELUT CSV file into the current directory
; :Author: raschwar, 6-jun-2019
; :History: 20-jun-2019, RAS,adapt to change in number of science energy edges, changed from 33 to 31
;     add the offset and gain to columns in the ELUT
;           30-jun-2019, RAS, added tvac reader for h5 file
;           01-jul-2019, RAS, use time2file for date string, change reader in stx_calib_fit_data_prep
;           31-aug-2022, ECMD, alternative option to produce a starlet compatible version 
;           11-jul-2023, ECMD, allow pass in of energy bin edges and non-integer edge values
;           
;-
pro stx_write_elut, gain_in, offset_in, h5 = h5, scale = scale, table_header = table_header, path = path, $
  starlet = starlet, science_energy_edges = science_energy_edges

  default, scale, 4.0 ;scale is 4.0 if the gain is for the 1024 ADC fits.
  default, h5, 'fitsresults.h5'
  default, path, [curdir(), concat_dir( concat_dir('SSW_STIX','dbase'),'detector')]
  npixel = 12
  ndet   = 32
  ndetxnpix = npixel * ndet
  h5_path = file_search( path, h5, count = h5_count)
  if ~exist(gain_in) or ~exist(offset_in) && h5_count ge 1 then begin
    ;The h5 file from O Grimm has gain and offsets from fitting ADC1024 calibration data
    h = stx_calib_read_tvac(path=path);
    gain = h.gain / scale
    offset = h.offset * scale
  endif else begin
    if exist(gain_in) and exist(offset_in) then begin
      gain = gain_in
      offset = offset_in
    endif else message, 'No gain or offset information. Either the parameters are missing or the fitsresults file is missing

  endelse
  ;Check to see that gain is ~0.1 and not ~0.4, the 4096 adc channel gain should be lt 0.2
  if max(gain) gt 0.2 then message,'Stop. Using ADC1024 gain and not ADC4096 gain
  science_edg = exist( science_energy_edges ) ? science_energy_edges : stx_science_energy_channels(/edges_1)
  nenergy_edg = n_elements(science_edg)
  ad_channel = reproduce( offset[*], nenergy_edg) + 1.0/gain[*] # science_edg

  ad_id = bytarr( 2,npixel,ndet)

  if keyword_set(starlet) then begin

    for i=0,31 do ad_id[1,*,i] = indgen(npixel)
    for i=0,31 do ad_id[0,*,i] = i + intarr(npixel) + 1
    ad_channel = reform( transpose(ad_channel), nenergy_edg, npixel, ndet)

    table = reform( [ ad_id, round( ad_channel)], nenergy_edg+2, ndetxnpix )
    stable = strarr( nenergy_edg+2, ndetxnpix)
    stable[0:*,*] = strtrim( table,2 )
    ;Change to date string from time2file which can be read by file2time
    sdate = time2file( anytim(systime(/sec),fid='sys'),/date)
    write_csv, 'elut_table_starlet_'+sdate+'.csv',stable

  endif else begin

    for i=0,31 do ad_id[0,*,i] = indgen(npixel)
    for i=0,31 do ad_id[1,*,i] = i + intarr(npixel)
    ad_channel = reform( transpose(ad_channel), nenergy_edg, npixel, ndet)

    table = reform( [ ad_id, round( ad_channel)], nenergy_edg+2, ndetxnpix )
    stable = strarr( nenergy_edg+4, ndetxnpix)
    stable[0,*] = string( offset[*], format='(f9.4)')
    stable[1,*] = string( gain[*], format='(f9.6)')
    stable[2:*,*] = strtrim( table,2 )
    header = ['Offset','Gain keV/ADC','Pixel','Detector','ADC Edge '+$
      strtrim( indgen(nenergy_edg),2)+' - ' + strtrim(string(science_edg,format='(f6.2)'),2) + ' keV']
    default, table_header, ['Based on ECC fit measurements to calibration runs xxxx to yyyy provided by O Limousin.' + $
      ' From ELUT_ECC_para_xxx_yyyy.fits', $
      'Channel energy edges obtained from stx_science_energy_channels(/edges_1) ']
    ;Change to date string from time2file which can be read by file2time
    sdate = time2file( anytim(systime(/sec),fid='sys'),/date)
    write_csv, 'elut_table_'+sdate+'.csv',stable, header = header, table_header = table_header

  endelse




end
