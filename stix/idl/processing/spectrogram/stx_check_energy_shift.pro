;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_check_energy_shift
;
; :description:
;
;    This function checks the time of the observation and returns an average energy
;    shift if required.
;
;    When STIX was switched on during the RSCW of November 2020 the detector settings
;    resulted in a shift of energy calibration. For the duration of this RSCW until the
;    upload of an ELUT which accounts for this a shift of the energy science channel
;    boundaries is needed.
;
; :categories:
;     spectroscopy, io
;
; :params:
;    start_time : in, required, type="string"
;             The start time of the observation being analysed
; :returns:
;    expected_energy_shift: the expected energy shift that should be applied in keV
;
; :examples:
;    expected_energy_shift = stx_check_energy_shift('2020-11-18T00:00:00')
;
; :history:
;    21-Jul-2022 - ECMD (Graz), initial release
;
;-
function stx_check_energy_shift, start_time

  ; If time range of observation is during Nov 2020 RSCW apply average energy shift of -1.6 keV by default
  expected_energy_shift = (anytim(start_time) gt anytim('2020-11-15T00:00:00') $
    and anytim(start_time) lt anytim('2020-12-04T00:00:00')) $
    ? -1.6 : 0.

  if expected_energy_shift ne 0 then begin
    print, '***********************************************************************'
    print, 'Warning: Due to the energy calibration in the selected observation time'
    print, 'a shift of -1.6 keV has been applied to all science energy bins.'
    print, '************************************************************************'
  endif

  return, expected_energy_shift
end
