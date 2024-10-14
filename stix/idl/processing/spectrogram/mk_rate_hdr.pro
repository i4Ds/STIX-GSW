;==============================================================================
;+
; Name: mk_rate_hdr
;
; Category: HESSI, UTIL
;
; Purpose: Make a basic FITS header for a RATE EXTENSION and merge it
; with an optional input header.
;
; Calling sequence:
; new_hdr = mk_rate_hdr( hdr, N_ROWS=256 )
;
; Inputs:
; hdr - FITS header to merge with rate header.
;
; Outputs:
; Returns a valid FITS RATE extension header.
;
; Input keywords:
; N_ROWS - number of rows in RATE extension
; EVENT_LIST - Set if the extension is an event list, not a rate.
;
; Output keywords:
; ERR_MSG = error message.  Null if no error occurred.
; ERR_CODE - 0/1 if [ no error / an error ] occurred during execution.
;
; Calls:
; fxaddpar, fxbhmake, is_member, trim, merge_fits_hdrs
;
; Written: Paul Bilodeau, RITSS / NASA-GSFC, 18-May-2001
;
; Modification History:
; 28-June-2001 Paul Bilodeau - added event_list keyword.  Removed N_CHAN
;   keyword and ability to merge time independent data into the header.
; 01-Sep-2004  Sandhia Bansal - Remove TIME-OBS and TIME-END.  This information
;                               is already included in DATE-OBS and DATE-END.
; 03-Sep-2004  Sandhia Bansal - Added several keywords that are required for
;                 RATE extension. The values are now passed to this function via
;                 rate_struct structure.  Also add the fitswrite object fptr to
;                 the argument list so that the keys can be written via this pointer
;                 instead of using fx-routines directly.
; 24-Sep-2004  Sandhia Bansal - Write Author keyword.
; 09-Nov-2004  Sandhia Bansal - Write GEOAREA keyword.
; 20-Nov-2004  Sandhia Bansal - Write BACKAPP, DEADAPP, VIGNAPP, OBSERVER AND
;                               TIMVERSN keywords.
; 26-Apr-2019, Kim Tolbert - prevent a crash by making sure rate_hdr is defined even if hdr isn't
; 16-Jul-2024, F. Schuller (AIP) - correct typos in header keywords
; 
;-
;------------------------------------------------------------------------------
FUNCTION mk_rate_hdr, hdr, rate_struct, N_ROWS=n_rows, EVENT_LIST=event_list, $
  ERR_MSG=err_msg, ERR_CODE=err_code, fptr=fptr, _EXTRA=_extra

  err_code = 1
  err_msg = ''

  CATCH, err
  IF err NE 0 THEN BEGIN
    err_msg = !err_string
    RETURN, ''
  ENDIF

  IF N_Elements( n_rows ) EQ 0L THEN n_rows = -1L

  IF n_rows LE 0L THEN BEGIN
    err_msg = 'Cannot initialize header with ' + trim( n_rows ) + ' rows.'
    RETURN, ''
  ENDIF

  extname = Keyword_Set( event_list ) ? 'EVENTS' : 'RATE'


  ;fxbhmake, rate_hdr, n_rows, /DATE
  fptr->Addpar, 'EXTNAME',  extname, 'Extension Name'
  fptr->Addpar, 'TELESCOP', rate_struct.telescope, 'Name of the Telescope or Mission'
  fptr->Addpar, 'INSTRUME', rate_struct.instrument, 'Name of the instrument'
  fptr->Addpar, 'FILTER',   rate_struct.filter, 'Filter in use'
  fptr->Addpar, 'OBJECT',   rate_struct.object, 'Observed object'
  fptr->Addpar, 'RA',       rate_struct.ra, 'Right Ascension (in degrees) '
  fptr->Addpar, 'DEC',      rate_struct.dec, 'Declination (in degrees)'
  fptr->Addpar, 'RA_NOM',   rate_struct.ranom
  fptr->Addpar, 'DEC_NOM',  rate_struct.decnom
  fptr->Addpar, 'ORIGIN',   rate_struct.origin

  fptr->Addpar, 'TIMEUNIT', rate_struct.timeunit, 'Unit for TIMEZERO, TSTARTI and TSTOPI'
  fptr->Addpar, 'TIMEREF',  rate_struct.timeref, 'Reference frame for the times'
  fptr->Addpar, 'MJDREF',   float(rate_struct.mjdref), 'TIMESYS in MJD (d)'
  fptr->Addpar, 'TIMESYS',  rate_struct.timesys, 'Reference time in YYYY MM DD hh:mm:ss'
  fptr->Addpar, 'TIMEZERO', rate_struct.timezero, 'Start day of the first bin rel to TIMESYS'
  fptr->Addpar, 'TSTARTI',  rate_struct.tstarti, 'Integer portion of start time rel to TIMESYS'
  fptr->Addpar, 'TSTARTF',  rate_struct.tstartf, 'Fractional portion of start time'
  fptr->Addpar, 'TSTOPI',   rate_struct.tstopi, 'Integer portion of stop time rel to TIMESYS'
  fptr->Addpar, 'TSTOPF',   rate_struct.tstopf, 'Fractional portion of stop time'
  fptr->Addpar, 'TASSIGN',  rate_struct.tassign, 'Place of time assignment'
  fptr->Addpar, 'TIERRELA', rate_struct.tierrela, 'Relative time error'
  fptr->Addpar, 'TIERABSO', rate_struct.tierabso, 'Absolute time error'
  fptr->Addpar, 'ONTIME',   rate_struct.exposure, 'Exposure time in seconds'
  fptr->Addpar, 'TELAPSE',  rate_struct.telapse, 'Elapsed time in seconds'
  fptr->Addpar, 'CLOCKCOR', rate_struct.clockcor, 'Clock Correction to UT'
  fptr->Addpar, 'POISSERR', rate_struct.poisserr, 'Poission Error'
  fptr->Addpar, 'VERSION',  rate_struct.version, 'File format version'

  fptr->Addpar, 'EQUINOX',  rate_struct.equinox, 'Equinox of celestial coordinate system'
  fptr->Addpar, 'RADECSYS', rate_struct.radecsys, 'Coordinate frame used for equinox'
  fptr->Addpar, 'HDUCLASS', 'OGIP', 'File conforms to OGIP/GSFC convention'
  fptr->Addpar, 'HDUCLAS1', 'SPECTRUM', 'File contains spectrum'
  fptr->Addpar, 'HDUCLAS2', rate_struct.hduclas2, 'Extension contains a spectrum'
  fptr->Addpar, 'HDUCLAS3', 'RATE', 'Extension contains rates'
  fptr->Addpar, 'HDUCLAS4', 'TYPE:II', 'Multiple PHA files contained'
  fptr->Addpar, 'HDUVERS',  '1.2', 'File conforms to this version of OGIP'
  fptr->Addpar, 'TIMVERSN', 'OGIP/93-003', 'OGIP memo number where the convention used'
  fptr->Addpar, 'ANCRFILE',  rate_struct.ancrfile, 'Name of the corresponding ancillary response file'
  fptr->Addpar, 'AREASCAL',  rate_struct.areascal, 'Area scaling factor'
  fptr->Addpar, 'BACKFILE',  rate_struct.backfile, 'Name of the corresponding background file'
  fptr->Addpar, 'BACKSCAL',  rate_struct.backscal, 'Background scaling factor'
  fptr->Addpar, 'CORRFILE',  rate_struct.corrfile, 'Name of the corresponding correction file'
  fptr->Addpar, 'CORRSCAL',  rate_struct.corrscal, 'Correction scaling factor'
  fptr->Addpar, 'EXPOSURE',  rate_struct.exposure, 'Integration time, corrected for deadtime and data drop-out etc.'
  fptr->Addpar, 'GROUPING',  rate_struct.grouping, 'No grouping of data has been defined'
  fptr->Addpar, 'QUALITY',   rate_struct.quality, 'No quality information is specified'
  fptr->Addpar, 'DETCHANS',  rate_struct.detchans, 'Total number of detector channels available'
  fptr->Addpar, 'CHANTYPE',  rate_struct.chantype, 'Channels assigned by detector electronics'
  fptr->Addpar, 'GEOAREA',   rate_struct.area, 'Detector area for data in fit results (cm^2)'

  fptr->Addpar, 'VIGNET',  rate_struct.vignet
  fptr->Addpar, 'DETNAM',  rate_struct.detnam, 'Detector name'
  fptr->Addpar, 'NPIXSOU', rate_struct.npixsou
  fptr->Addpar, 'AUTHOR',  rate_struct.author, 'Name of program that produced this file'

  fptr->Addpar, 'BACKAPP', rate_struct.backapp, 'Flag to indicate whether correction was applied'
  fptr->Addpar, 'DEADAPP', rate_struct.deadapp, 'Flag to indicate whether correction was applied'
  fptr->Addpar, 'VIGNAPP', rate_struct.vignapp, 'Flag to indicate whether correction was applied'

  fptr->Addpar, 'OBSERVER', rate_struct.observer, 'Name of the user who genrated the file'

  fptr->Addpar, 'TIMVERSN', rate_struct.timversn, 'OGIP memo number where the convention used'


  IF Size( hdr, /TYPE ) EQ 7 THEN BEGIN
    rate_hdr = merge_fits_hdrs( hdr, fptr->getheader(), ERR_MSG=err_msg, $
      ERR_CODE=err_code )

    ;rate_hdr = merge_fits_hdrs( hdr, rate_hdr, ERR_MSG=err_msg, $
    ;  ERR_CODE=err_code )
    IF err_code THEN RETURN, 0
  ENDIF ELSE begin
    rate_hdr = fptr->getheader()  ; added 26-Apr-2019
    err_code = 0
  ENDELSE

  ; remove SIMPLE or EXTEND keywords - they don't belong in an extension header
  non_simple = $
    Where( Strmid( Strupcase(rate_hdr), 0, 6) NE 'SIMPLE', n_non_simple )
  IF n_non_simple GT 0L THEN rate_hdr = rate_hdr[ non_simple ]

  non_extend = $
    Where( Strmid( Strupcase(rate_hdr), 0, 6) NE 'EXTEND', n_non_extend )
  IF n_non_extend GT 0L THEN rate_hdr = rate_hdr[ non_extend ]

  RETURN, rate_hdr

END
