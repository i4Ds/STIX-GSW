

;+
; :Description:
;    This function returns the science energy channel table that associates the science energy channel (0-32) with the
;    adc values (0-4095) for each detector/pixel. The ad_energy_filename (csv) is read and loaded into the table
;    and stored in common only accessible through this function.
;    
; :Examples:
;    The first is as a structure which reads the science channel ad edge table and returns it:
;    IDL> tbl = stx_energy_lut_get(  )
;      IDL> help, tbl
;      TBL             STRUCT    = -> <Anonymous> Array[12, 32]
;      IDL> help, tbl,/st
;      ** Structure <ae28700>, 3 tags, length=70, data length=70, refs=2:
;         DETECTOR_NUMBER INT              1  ;runs 1-32
;         PIXEL_NUMBER    INT              0  ;runs 0-11
;         ADCHAN_EDG      INT       Array[33]
;     The second possibility is as the science channel lookup table giving the science channel index (0-32)
;     at each ad channel address (0-4095) for each detector and pixel.
;     The table is set to 99 for both low and high channels outside of the range of the science energy channels 
;      IDL> tbl = stx_energy_lut_get( /full_table )
;      IDL> help, tbl
;      TBL             INT       = Array[32, 12, 4096]
;      IDL> pmm, tbl
;      % Compiled module: PMM.
;           0.000000      99.0000
;      IDL> print, where( tbl[0, 0, *] eq 2 )
;              2062        2063        2064        2065        2066        2067        2068        2069        2070        2071
;      IDL> print, where( tbl[0, 0, *] eq 20 )
;              2393        2394        2395        2396        2397        2398        2399        2400        2401        2402        2403        2404
;              2405        2406        2407        2408        2409        2410        2411        2412        2413        2414        2415        2416
;              2417        2418        2419        2420        2421        2422        2423        2424        2425        2426        2427        2428
;              2429        2430        2431        2432        2433        2434        2435        2436        2437        2438        2439        2440
;              2441
;
;
;
; :Keywords:
;    reset - if set, reload the tables/variables in common from the csv file
;    directory - location of the ad_energy_filename
;    ad_energy_filename - name or full descriptor of the ad_channel energy boundary table (csv)
;    full_table - if set, return the flat table of the science channels at each ad channel value dim intarr( 32, 12, 4096 )
;    
; :Author: richard.schwartz@nasa.gov, 2-jul-2015
; :History: ras, 9-jul-2015, small change to last bin in full_energy_table to eliminate science channel 32 from closing the channels
;-
function stx_energy_lut_get,  $
  reset = reset, $
  directory = directory, $
  ad_energy_filename = ad_energy_filename, $
  full_table = full_table, $
  offset_gain_file = offset_gain_file, $
  error = error

common stx_energy_lut, adchan_edg_str, full_energy_table, dummy
default, reset, 0
default, full_table, 0
default, error, 'Unknown Error'
if reset or ~keyword_set( adchan_edg_str ) then begin 
  default, directory, ('STX_DET')
  default, ad_energy_filename,'ad_energy_table'
  filename = form_filename( ad_energy_filename, '.csv')
  filename = loc_file( path = directory, filename, count = nf )
  if nf eq 0 then begin
    error = 'Cannot find '+ filename + ' Returning -1'
    message, /continue, error
    return, -1
    endif
    
  ;Read the data file, flat array although comma separated, no header
  out = rd_tfile( filename[0], /conver, /autocol, delim = ',' ) 
  
  adchan_edg_str = replicate( create_struct( ['detector_number','pixel_number', 'adchan_edg' ], 0, 0, intarr(33) ), 384 )
  for i=0, 1 do adchan_edg_str.(i) =  reform( out[i,*] ) ;load detector_number and pixel_number
  adchan_edg_str.adchan_edg = out[ 2:*, *]
  
  adchan_edg_str = reform( adchan_edg_str, 12, 32 )
  
  full_energy_table = intarr(32,12,4096) + 99
  for id = 0, 31 do for ip = 0,11 do begin
    edges = adchan_edg_str[ ip, id ].adchan_edg
    full_energy_table[ id, ip, edges[0] : edges[32] -1 ] = value_locate( edges, edges[0] + indgen(edges[32]-edges[0]) )
    endfor
  
endif
error = 0
return, full_table ? full_energy_table : adchan_edg_str
end
