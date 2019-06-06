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
;-
pro stx_write_elut, gain, offset, h5 = h5, scale = scale, table_header = table_header

  default, scale, 4.0
  if file_exist( h5) then begin
    r = h5_parse( h5, /read)
    gain = r.fitgain._data / scale
    offset = r.fitoffset._DATA * scale
  endif
  science_edg = exist( science_energy_edges ) ? science_energy_edges : stx_science_energy_channels(/edges_1)

  ad_channel = reproduce( offset[*],33) + 1.0/gain[*] # science_edg

  ad_id = bytarr( 2,12,32)
  for i=0,31 do ad_id[0,*,i] = indgen(12)
  for i=0,31 do ad_id[1,*,i] = i + intarr(12)
  ad_channel = reform( transpose(ad_channel),33,12,32)

  table = reform( [ ad_id, round( ad_channel)], 35, 384 )
  header = ['Pixel','Detector','ADC Edge '+$
    strtrim( indgen(33),2)+' - ' + strtrim( fix(science_edg),2) + ' keV']
  default, table_header, ['Based on the TVAC measurements by O Grimm May/June 2017.' + $
    ' From STIX_TVAC_Data_MayJune2017\Nominal\FitResults.mat', $
     'Channel energy edges obtained from stx_science_energy_channels(/edges_1) ']
  write_csv,'elut_table.csv',table, header = header, table_header = table_header
end
