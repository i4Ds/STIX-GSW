;==============================================================================
;+
; Name: stx_spectrum2fits
;
; Category: FITS, UTIL
;
; Purpose: Write spectral rate data to a FITS file.
;
; Calling sequence:
;     spectrum2fits, filename, WRITE_PRIMARY_HEADER=1,
;       PRIMARY_HEADER=primary_header, EXTENSION_HEADER=extension_header,
;       DATA=rate_data, ERROR=rate_error, TSTART=start_times, TSTOP=stop_times,
;       MINCHAN=1, MAXCHAN=number_of_channels,
;       E_MIN=min_channel_energies, E_MAX=max_channel_energies, E_UNIT='keV',
;       ERR_CODE=had_err, ERR_MSG=err_msg
;
; Inputs:
; filename - name of FITS file to write.
;
; Outputs:
;
; Input keywords:
; WRITE_PRIMARY_HEADER - set this keyword to write a primary header to
;                        the file.
; PRIMARY_HEADER - primary header for the file.  This contains any information
;       that should be in the primary header in addition to
;       the mandatory keywords.  Only used if
;       WRITE_PRIMARY_HEADER is set.
; EXTENSION_HEADER - header for the RATE extension, with any necessary
;         keywords.
; EVENT_LIST - set this keyword if a list of events is being written
;              to the file.
; _EXTRA - Any keywords set in _EXTRA will be integrated into the extension
;      structure array based on the number of elements.  If an entry has
;      n_channel entries, it will be duplicated n_input spectra
;      times and will be stored as a vector in the structure
;      array.  If it has n_input spectra entries, each entry will
;      be a scalar in the corresponding structure array element.
;      The spectral data are passed in via the DATA keyword.
;
; The following keywords control writing data into the RATE
; extension and are processed in wrt_rate_ext:
; DATA - a [n_channel x n_input spectra / n_channel x n_detector x $
;    n_input_spectra] array containing the the
;    counts/s or counts for each spectrum in each channel.
; ERROR - an array containing the uncertainties on DATA.  Deafults to the
;     square root of DATA.
; COUNTS - set if the column name for the data entry should be COUNTS
;          instead of the default RATE.
; UNITS - units for DATA
;  - a [ n_channel x n_input spectra / n_input spectra ] array
;            containing the livetime for each [ spectrum channel / spectrum ]
; TIMECEN - Full time or time from TIMEZERO for each input spectrum or
;           event.  Stored as TIME column within RATE extension.
; SPECNUM - Index to each spectrum.
; TIMEDEL - The integration time for each channel of each spectrum or
;           each spectrum.
; DEADC - Dead Time Correction for each channel of each spectra, each
;     spectrum, or each channel.  One of DEADC / LIVETIME should
;     be set.  If n_chan elements, this will be set in the header
;     for this extension.
; BACKV - background counts for each channel of each spectrum - OPTIONAL.
; BACKE - error on background counts for each channel of each spectrum.
;         OPTIONAL.  Defaults to the square root of the BACKV if BACKV is set.
;
; The following keywords control the data that are written in the ENEBAND
; extension are passed to wrt_eneband_ext:
; NUMBAND - number of energy bands.
; MINCHAN - a numband element array containing the minimum channel number in
;       each band.
; MAXCHAN - a numband element array containing the maximum channel number in
;       each band.
; E_MIN - a numband element array containing the minimum energy in each band.
; E_MAX - a numband element array containing the maximum energy in each band.
;
; Output keywords:
; ERR_MSG = error message.  Null if no error occurred.
; ERR_CODE - 0/1 if [ no error / an error ] occurred during execution.
;
; Calls:
; arr2str, str2arr, str2chars
;
;
; Modification History:
;   2002: Written by Paul Bilodeau, RITSS / NASA-GSFC
;   2024-07-16, F. Schuller (AIP): 
;    - copy from ssw/gen/idl/fits/spectrum2fits.pro 
;    - adapted to STIX data and compatibility with XSPEC:
;      * added columns EXPOSURE and SYS_ERR
;      * correct header keywords HDUCLAS3 and HDUCLAS4 in extension RATE
;      * update HDUCLAS2 keyword depending whether background was subtracted or not
;   
;-
;------------------------------------------------------------------------------
PRO stx_spectrum2fits, filename, $
                   WRITE_PRIMARY_HEADER=write_primary_header, $
                   PRIMARY_HEADER=prim_header, $
                   EXTENSION_HEADER=ext_header, $
                   NUMBAND=numband, $
                   MINCHAN=minchan, $
                   MAXCHAN=maxchan, $
                   E_MIN=e_min, $
                   E_MAX=e_max, $
                   E_UNIT=e_unit, $
                   EVENT_LIST=event_list, $
                   _EXTRA=_extra, $
                   ERR_MSG=err_msg, $
                   ERR_CODE=err_code

err_msg = ''
err_code = 0

IF Size( filename, /TYPE ) NE 7 THEN BEGIN
    err_msg = 'Need filename as first input.'
    GOTO, ERROR_EXIT
ENDIF

IF Keyword_Set( write_primary_header ) THEN BEGIN
    ; Create the primary header if necessary.
    IF Size( prim_header, /TYPE ) NE 7 THEN $
      fxhmake, prim_header, /EXTEND, /DATE

    fxaddpar, prim_header, 'AUTHOR', 'SPECTRUM2FITS'
    fxaddpar, prim_header, 'RA', 0.0, 'Source right ascension in degrees'
    fxaddpar, prim_header, 'DEC', 0.0, 'Source declination in degrees'
    fxaddpar, prim_header, 'RA_NOM', 0.0, 'r.a. nominal pointing in degrees'
    fxaddpar, prim_header, 'DEC_NOM', 0.0, 'dec. nominal pointing in degrees'
    fxaddpar, prim_header, 'EQUINOX', 2000.0, 'Equinox of celestial coordinate system'
    fxaddpar, prim_header, 'RADECSYS', 'FK5', 'Coordinate frame used for equinox'
    fxaddpar, prim_header, 'TIMVERSN', 'OGIP/93-003', 'OGIP memo number where the convention used'
    fxaddpar, prim_header, 'VERSION', '1.0', 'File format version number'

    fxwrite, filename, prim_header, ERRMSG=err_msg

    IF err_msg NE '' THEN BEGIN
        MESSAGE, 'ERROR writing primary header to ' + filename, /CONTINUE
        RETURN
    ENDIF
ENDIF

ext_kw_list = [  'SPEC_NUM', 'CHANNEL', 'TIMECEN', 'TIMEDEL', 'LIVETIME', 'DEADC', $
      'BACKV', 'BACKE', 'TIMEZERO', 'TSTART', 'TSTOP', 'EXPOSURE', 'SYS_ERR' ]

ext_st_list = [ 'SPEC_NUM', 'CHANNEL', 'TIME', 'TIMEDEL', 'LIVETIME', 'DEADC', $
      'BACKV', 'BACKE', 'TIMEZERO', 'TSTART', 'TSTOP', 'EXPOSURE', 'SYS_ERR' ]

wrt_rate_ext, filename, HEADER=ext_header, _EXTRA=_extra, $
              KW_LIST=ext_kw_list, ST_LIST=ext_st_list, $
              EVENT_LIST=event_list, ERR_MSG=err_msg, ERR_CODE=err_code

IF err_code THEN BEGIN
    MESSAGE, 'ERROR writing RATE extension to ' + filename, /CONTINUE
    RETURN
ENDIF

; Correct header keywords HDUCLAS3 and HDUCLAS4 (deeply hardcoded in mk_rate_hdr.pro)
; FSchuller, 2024-07-17
data_rate = mrdfits(filename, 1, head_rate)
sxaddpar, head_rate, 'HDUCLAS3', 'RATE', '  Extension contains rates', after='HDUCLAS2'
sxaddpar, head_rate, 'HDUCLAS4', 'TYPE:II', '  Multiple PHA files contained', after='HDUCLAS3'
sxdelpar, head_rate, 'HDUCALS3'
; POISSERR should be a boolean (not an integer)
sxaddpar, head_rate, 'POISSERR', boolean(0), '  Poisson Error'
; if background subtracted, update keyword
bg_sub = sxpar(head_rate, 'BACKAPP')
if bg_sub eq 1 then begin
  sxaddpar, head_rate, 'HDUCLAS2', 'NET', '  Extension contains a spectrum'
  sxaddpar, head_rate, 'BACKFILE', 'none'
endif else sxaddpar, head_rate, 'HDUCLAS2', 'TOTAL', '  Extension contains a spectrum'

fxwrite, filename, prim_header, ERRMSG=err_msg
mwrfits, data_rate, filename, head_rate

; 2nd extension: ENEBAND
wrt_eneband_ext, filename, HEADER=ext_header, NUMBAND=numband, $
                 MINCHAN=minchan, MAXCHAN=maxchan, E_MIN=e_min, E_MAX=e_max, $
                 E_UNIT=e_unit, ERR_MSG=err_msg, ERR_CODE=err_code

IF err_code THEN BEGIN
    MESSAGE, 'ERROR writing ENEBAND extension to ' + filename, /CONTINUE
    RETURN
ENDIF

ERROR_EXIT:
err_code = err_msg NE ''
IF err_code THEN BEGIN
    MESSAGE, err_msg, /CONTINUE
    err_msg = 'SPECTRUM2FITS: ' + err_msg
ENDIF

END
