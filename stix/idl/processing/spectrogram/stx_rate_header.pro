;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_rate_header
;
; :purpose:
;    Make rate header structure for stix spectrum fits file.
;
;
; :category:
;       helper methods
;
; :description:
;   Routine based on the form of the rate structure made in hsi_spectrum__fitswrite.
;
;
; :keywords:
;
;   nchan - the number of channels
;
;   exposure - exposure time
;
;   timezeri - integer part start time
;
;   tstartf - fractional part of start time (number of milliseconds divided by number of milliseconds per day)
;
;   tstopi - integer part of end time
;
;   tstopf - fractional part end time
;
;
; :returns:
;    Returns the structure rate structure needed for the headers inn the stix spectrum fits files.
;
; :calling sequence:
;    IDL> rate_struct = stx_rate_header( nchan = nchan, exposure = exposure, timezeri = timezeri, tstartf = tstartf , $
;         tstopi= tstopi, tstopf = tstopf )
;
;
;
; :history:
;       23-Sep-2014 – ECMD (Graz) - initial release
;       08-Aug-2022 – ECMD (Graz) - pass in basic info about background subtraction
;
;-

;+

;-

function stx_rate_header, nchan = nchan, $
  exposure = exposure, $
  timezeri = timezeri, $
  tstartf = tstartf, $
  tstopi = tstopi, $
  tstopf = tstopf, $
  backapp = backapp, $
  backfile = backfile


  rate_struct = {rate_header}
  rate_struct.telescope = 'Solar Orbiter'
  rate_struct.instrument = 'STIX'
  rate_struct.origin = 'STIX'
  rate_struct.timeunit = "d"
  rate_struct.timeref = "LOCAL"
  rate_struct.tassign = "SATELLITE"
  rate_struct.object = 'Sun'
  rate_struct.detchans = nchan
  rate_struct.chantype = "PI"
  rate_struct.areascal = 1.0
  rate_struct.backscal = 1.0
  rate_struct.corrscal = 1.0
  rate_struct.grouping = 0
  rate_struct.quality = 0
  rate_struct.exposure = exposure
  rate_struct.equinox = 2000.0
  rate_struct.radecsys = 'FK5'
  rate_struct.hduclas2 = 'TOTAL'   ; Extension contains a spectrum.
  mjdref = anytim('00:00 1-Jan-79', /MJD)
  rate_struct.mjdref = float(mjdref.mjd)
  rate_struct.timesys = strmid(anytim('00:00 1-Jan-79', /ccsds), 0, 19)
  rate_struct.timezero = timezeri - rate_struct.mjdref
  rate_struct.tstarti = timezeri - long(rate_struct.mjdref)
  rate_struct.tstartf = tstartf
  rate_struct.tstopi = tstopi - long(rate_struct.mjdref)
  rate_struct.tstopf = tstopf
  rate_struct.telapse = double(((tstopi-timezeri) + (tstopf-tstartf))*86400.0)
  rate_struct.clockcor = 'T'
  rate_struct.telapse = 0.0
  rate_struct.backapp = backapp
  rate_struct.backfile = backfile
  rate_struct.poisserr = 'F'
  rate_struct.version = '1.0'
  rate_struct.author = 'Unknown'
  rate_struct.observer = 'Unknown'
  rate_struct.timversn = 'OGIP/93-003'

  return, rate_struct


end
