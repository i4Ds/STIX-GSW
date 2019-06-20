;+
; :Description:
;    Using the measured gain (adc or adc4) gain and offset
;    write the ELUT (Energy LookUp Table) into a CSV file for all 384 STIX pixel/detectors
;    adc(4) bins are the adc (4096 channels) with two LSBs suppressed
;
; :Params:
;    gain   - adc(4) bin width in keV, nominally about 0.4
;    offset - adc(4) edge corresponding to 0.0 keV
;
; :Keywords:
;    h5    - if passed, matlab fitresults.mat file holding the gain and offset
;    scale - default is 4, using the fitted values from the calibration spectra on the 1024 compressed spectra
;    If based on the 4096 adc channels, then scale should be 1
; :Results:
;   Writes an ELUT CSV file into the working directory
; :Author: raschwar, 6-jun-2019
; :History: 20-jun-2019, RAS,adapt to change in number of science energy edges, changed from 33 to 31
;     add the offset and gain to columns in the ELUT
;-
pro stx_write_elut, gain_in, offset_in, h5 = h5, scale = scale, table_header = table_header

  default, scale, 4.0
  default, h5, 'fitsresults.h5'
  npixel = 12
  ndet   = 32
  ndetxnpix = npixel * ndet
  
  if ~exist(gain_in) or ~exist(offset_in) && file_exist( h5) then begin
    r = h5_parse( h5, /read)
    gain = r.fitgain._data / scale
    offset = r.fitoffset._DATA * scale
  endif else begin
    if exist(gain_in) and exist(offset_in) then begin
    gain = gain_in
    offset = offset_in
    endif else message, 'No gain or offset information. Either the parameters are missing or the fitsresults file is missing
    
  endelse
  science_edg = exist( science_energy_edges ) ? science_energy_edges : stx_science_energy_channels(/edges_1)
  nenergy_edg = n_elements(science_edg)
  ad_channel = reproduce( offset[*], nenergy_edg) + 1.0/gain[*] # science_edg


  ad_id = bytarr( 2,npixel,ndet)
  for i=0,31 do ad_id[0,*,i] = indgen(npixel)
  for i=0,31 do ad_id[1,*,i] = i + intarr(npixel)
  ad_channel = reform( transpose(ad_channel), nenergy_edg, npixel, ndet)

  table = reform( [ ad_id, round( ad_channel)], nenergy_edg+2, ndetxnpix )
  stable = strarr( nenergy_edg+4, ndetxnpix)
  stable[0,*] = string( offset[*], format='(f9.4)')
  stable[1,*] = string( gain[*], format='(f9.6)')
  stable[2:*,*] = strtrim( table,2 )
  header = ['Offset','Gain keV/ADC','Pixel','Detector','ADC Edge '+$
    strtrim( indgen(nenergy_edg),2)+' - ' + strtrim( fix(science_edg),2) + ' keV']
  default, table_header, ['Based on the TVAC measurements by O Grimm May/June 2017.' + $
    ' From STIX_TVAC_Data_MayJune2017\Nominal\FitResults.mat', $
    'Channel energy edges obtained from stx_science_energy_channels(/edges_1) ']
  sdate = anytim(systime(/sec),fid='sys',/vms,/date)
  write_csv,'elut_table_'+sdate+'.csv',stable, header = header, table_header = table_header
end
