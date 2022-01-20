;+
;
; PROJECT:
; HESSI
;
; NAME:
; stx_read_data
;
; PURPOSE:
; Read STX data from a FITS file for OSPEX
;
; CATEGORY:
; SPEX
;
; CALLING SEQUENCE:
; stx_read_data, FILES=files, data_str=data_str, ERR_CODE=err_code, ERR_MSG=err_msg
;
; KEYWORDS:
;   FILES - (INPUT) Scalar or vector string of file names to read
;   DATA_STR - (OUTPUT) Structure containing info read from file (described below)
;   ERR_CODE - (OUTPUT) 0 means success reading file(s). 1 means failure
;   ERR_MSG - (OUTPUT) string containing error message if any. '' means no error.

; OPTIONAL OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; History:
; 25-Nov-2015, Kim. Renamed from read_hessi_4_ospex to use for stx spectrum file. Also added
;   data_name, deconvolved, pseudo_livetime to output structure. Set spex_file_reader to 'stx_read' to use.
; 28-Sep-2015, Kim. Cleaned up header, and removed rhessi-specific parts of code (not totally)
;
;-
;------------------------------------------------------------------------------
PRO stx_read_sp_data, FILES=files, $
                        data_str=data_str, $
                        ERR_CODE=err_code, $
                        ERR_MSG=err_msg, $
                        _REF_EXTRA=_ref_extra

data_str = -1

err_code = 0
err_msg = ''

respfile = ''

delta_light= 1.0

if files[0] eq '' then begin
    err_code=1
    err_msg = 'No spectrum file selected.'
    return
endif

dir = file_dirname(files[0])

atten_states = -1

IF is_fits(files[0]) THEN BEGIN
    fits2spectrum, FILE=files[0], $
                   PRIMARY_HEADER=p_hdr, $
                   EXT_HEADER=sp_hdr, $
                   EXT_DATA=sp_data, $
                   ENEBAND_DATA=en_data, $
                   _EXTRA=_ref_extra, $
                   ERR_MSG=err_msg, $
                   ERR_CODE=err_code, /silent

    IF err_code THEN RETURN

  detused = fxpar( sp_hdr, 'DETUSED', COUNT=rcount )
  if rcount eq 0 then detused = '' else begin
    detused = str_replace (detused, 'SEGMENTS: ', '')
    detused = str_replace (detused, '|', ' ')
  endelse

	sum_flag = fxpar(sp_hdr, 'SUMFLAG', count=count)
	if count gt 0 and sum_flag eq 0 then begin
	  if n_elements(str2arr(detused, ' ')) gt 1 then begin  ; check for > 1 det
	  	err_code = 1
	  	err_msg = 'OSPEX can not handle spectrum files with >1 detectors that are not summed (sum_flag=0). Aborting'
	  	return
	  endif
	endif

    ut_edges = Dblarr( 2, N_Elements(sp_data) )
    IF tag_exist( sp_data, 'TSTART') THEN BEGIN
       ut_edges[0,*] = sp_data.tstart
       ut_edges[1,*] = sp_data.tstop
    ENDIF ELSE BEGIN
        ;This is the new, compliant formulation for time in the RATE files.
        timedel = tag_exist(sp_data, 'TIMEDEL')? $
          sp_data.timedel : float( fxpar('TIMEDEL'))
        ut_edges = (sp_data.time- timedel / 2.0)## (fltarr(2)+1.0)
        ut_edges[1,*] = ut_edges[1,*] + timedel
    ENDELSE
    ct_edges = Transpose( [ [ en_data.e_min ] , [ en_data.e_max ] ] )

    timesys =   strtrim( fxpar(sp_hdr, 'TIMESYS'), 2)

    IF timesys EQ 'MJD' then begin
        mjd = replicate( anytim(0.0,/mjd), n_elements(ut_edges) )
        ;; convert to MJdays
        mjd.mjd = long( ut_edges[*] )
        ;; convert to millisec
        mjd.time = long( ( ut_edges[*] MOD 1. ) * 8.64e7)
        ;; convert to ut seconds format from 1-jan-1979
        ut_edges[0] = anytim( mjd, /sec)
    ENDIF

    IF timesys eq '1979-01-01T00:00:00' then begin
       mjdref = fxpar(sp_hdr, 'MJDREF')
       timezero = fxpar(sp_hdr, 'TIMEZERO')
       ut_edges = mjd2any(timezero+mjdref) + ut_edges
    endif
    
    read_stx_4_ospex_params, files[0], param, status
    if status then begin
       ; get attenuator info from object param interval_atten_state or sp_atten_state
       ; interval_atten_state should have one element per time bin, with tags state and uncertain
       ; (in some cases, only one value so have to replicate to match number of time bins)
       ; save in atten_states one value per time interval - the atten state or -99 if uncertain

       if tag_exist(param, 'interval_atten_state') then begin
         interval_atten_state = param.interval_atten_state
         if n_elements(interval_atten_state) eq 1 then begin  ; added 30-may-05
          temp = interval_atten_state
          interval_atten_state =  replicate( {state:0b, uncertain:0b}, n_elements(ut_edges[0,*]))
          interval_atten_state.state = temp.state
          interval_atten_state.uncertain = temp.uncertain
         endif
       endif else begin
         ; if interval_atten_state not there, but sp_atten_state is, reconstruct interval_atten_state
         ; from it (same code as in HSI_Spectrum::Process_Hook_Post)
         if tag_exist(param,'sp_atten_state') then begin
          interval_atten_state =  replicate( {state:0b, uncertain:0b}, n_elements(ut_edges[0,*]))
          sp_atten_state = param.sp_atten_state
          if n_elements(sp_atten_state.state) eq 1 then begin
              interval_atten_state.state = sp_atten_state.state
              interval_atten_state.uncertain = 0
          endif else begin
              w0  = reform( value_locate(  sp_atten_state.time, ut_edges[0,*] ) >0)
              w1  = reform(value_locate(  sp_atten_state.time, ut_edges[1,*] ) >0 )
              interval_atten_state.state = sp_atten_state.state[w0]
              uncertain = where(w1 ne w0 , nuncertain)
              if nuncertain ge 1 then interval_atten_state[uncertain].uncertain =1
          endelse
         endif
       endelse
       if exist(interval_atten_state) then begin
         atten_states = fix(interval_atten_state.state)
         q = where (interval_atten_state.uncertain eq 1, count)
         if count gt 0 then atten_states[q] = -99
       endif else begin
         atten_states = -1
       endelse

      ; if used_xyoffset is available, use it, otherwise use xyoffset
      xyoffset = tag_exist(param, 'used_xyoffset') ? param.used_xyoffset : [-9999.,-9999.]
    endif else begin
      atten_states = -1
      xyoffset = [-9999.,-9999.]
    endelse

 
ENDIF else begin
  message,'Input file is not a FITS file.', /cont
  return
Endelse

sp_tags = Tag_Names( sp_data )
data_tags = [ 'FLUX', 'RATE', 'COUNTS' ]
ercounts_idx = -1
FOR i=0, N_Elements( sp_tags )-1L DO BEGIN
    match = Where( sp_tags[i] EQ data_tags, n_match )
    IF n_match GT 0 THEN BEGIN
        rcounts_idx = i
        unit = data_tags[ match[ 0 ] ]
    ENDIF
    ; Expect either ERATE or STAT_ERR for a column containing errors
    ematch = Where( sp_tags[i] EQ 'E' + data_tags, n_ematch ) or $
             Where (sp_tags[i] EQ 'STAT_ERR', n_ematch )
    IF n_ematch GT 0 THEN ercounts_idx = i
ENDFOR

rcounts = sp_data.( rcounts_idx )
if n_ematch gt 0 then ercounts = ercounts_idx[0] GT -1 ? sp_data.( ercounts_idx ) : sp_data.error else ercounts = 0*rcounts

ltime = tag_exist(sp_data, 'livetime')? $
  sp_data.livetime: 0*rcounts +1

default, area_stat,0
area = fxpar(sp_hdr, 'GEOAREA', COUNT=area_cnt)
IF area_cnt GT 0 THEN area = (st2num( area, area_stat ))[0]
IF 1 - area_cnt THEN area = 1.

; Make any 3-D arrays into 2-D - multiple detector sets must be combined for
; analysis

; Until we're ready to handle it carefully, don't allow data array to be
; anything but 2-d (energy, time)
if n_dimensions( rcounts) gt 2 then begin
	err_code = 1
	err_msg = 'Data array is invalid (has '+trim(n_dimensions(rcounts))+$
		' dims.  Can only handle (nenergyxntime).'
	return
endif

IF n_dimensions( rcounts ) EQ 3 THEN rcounts = Total( rcounts, 2 )

IF n_dimensions( ercounts ) EQ 3 THEN ercounts = total( ercounts, 2 )

;The next line is an approximation, it needs refinement
;That's why this shouldn't be done here.
IF n_dimensions( ltime ) EQ 3 THEN ltime = total( ltime,2 )

nbin = n_elements( ut_edges )/2
nchan = n_elements( ct_edges )/2

; transpose the rcounts, ercounts, and ltime matrices, if necessary
delta_light = get_edges( ct_edges, /width ) # ( 1+fltarr(nbin) )
acctime = float( get_edges( ut_edges, /width)) ## ( 1+fltarr(nchan) )

IF n_elements( ltime ) EQ 1 THEN $
  ltime = replicate(ltime,nbin)

IF n_elements( ltime ) NE n_elements(rcounts) THEN $
  ltime = ltime ## (1+fltarr(nchan))

CASE unit OF
    'FLUX': BEGIN
        rcounts = rcounts * area * acctime * ltime * delta_light
        ercounts = ercounts * area * acctime * ltime * delta_light
    END
    'RATE': BEGIN
        rcounts = rcounts * acctime * ltime
        ercounts = ercounts * acctime * ltime
    END
    ELSE: ;; It's already counts.
ENDCASE

ltime = ltime * acctime

;units = ' s!u-1!n cm!u-2!n keV!u-1!n'
units = 'counts'
wchan = Lindgen( nchan )

start_time = anytim( fxpar( p_hdr, 'DATE_OBS', count=c ), /vms )
if c eq 0 then start_time = anytim( fxpar( p_hdr, 'DATE-OBS' ), /vms)
end_time = anytim( fxpar( p_hdr, 'DATE_END', count=c ), /vms )
if c eq 0 then end_time = anytim( fxpar( p_hdr, 'DATE-END' ), /vms)

title = 'STX SPECTRUM'

; Look for a response file in the spectral header
rfile = fxpar( sp_hdr, 'RESPFILE', COUNT=rcount )

IF rcount GT 0 THEN BEGIN
    ;; First try to read the respfile name as stored in the FITS
    ;; header.  If that fails, look for the file in the directory
    ;; where the spectrum file was found.
    respfile = loc_file( rfile, COUNT=count, LOC=loc )

    IF count LE 0 THEN BEGIN
        rfile_in_specdir = concat_dir( dir, file_basename(rfile) )
        respfile = loc_file( rfile_in_specdir, COUNT=count, LOC=loc )
    ENDIF

    IF count GT 0 THEN BEGIN
        IF file_dirname(respfile) eq '.' then respfile = concat_dir( loc[0], respfile[0] )
    ENDIF ELSE BEGIN
        print, ['FILE ' + files[0]+':', $
                   'has RESPFILE: ' + rfile, $
                   'RESPFILE: ' + rfile + ' not found.' ]
        respfile = ''
    ENDELSE

ENDIF ELSE respfile = ''

 
data_str = { $
    START_TIME: start_time, $
    END_TIME: end_time, $
    RCOUNTS: float(rcounts), $
    ERCOUNTS: ercounts, $
    UT_EDGES: ut_edges, $
    UNITS: units, $
    AREA: area, $
    LTIME: ltime, $
    CT_EDGES: ct_edges, $
    data_name: 'STX', $
    TITLE: title, $
    RESPFILE: respfile, $
    detused: detused, $
    atten_states: atten_states, $
    deconvolved: 0, $
    pseudo_livetime: 0, $
    xyoffset: xyoffset }

END
