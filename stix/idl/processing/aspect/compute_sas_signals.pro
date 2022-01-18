;+
; Description :
;   This function computes the expected SAS signals for all four arms, given vectors of X/Y-offsets
;   (in the SAS frame) and corresponding UTC times. It returns a data object with same structure as
;   that returned when reading a file.
;
; Category    : simulation / analysis
;
; Syntax      : result = compute_sas_signals(xoff, yoff, in_UTC, aperfile, dx=dx, quiet=quiet)
;
; Inputs      :
;   xoff/yoff = vectors (fn. of time) of Sun position in SAS frame [m]
;   in_UTC    = vector of strings containing UTC times
;   aperfile  = name (with absolute path) of the file with description of apertures geometry
;
; Output      :
;   result    = a data object with same structure as that returned when reading a file
;
; Keywords    :
;   dx        = linear step interval [m] - default: 1.e-6
;   quiet     : if set, turn off display of message "Computing signal arm ..."
;   
; History     :
;   2020-01-31, F. Schuller (AIP) : created
;   2020-02-04, FSc : add conversion to nA
;   2020-02-05, FSc : make computation for one arm only
;   2020-06-18, FSc : removed roll angles (included in xoff, yoff)
;   2021-12-16, FSc : pass name (with absolute path) of file with description of apertures as argument
;
;-
function compute_sas_signals, xoff, yoff, in_UTC, aperfile, dx=dx, quiet=quiet
  default, dx, 1.e-6
  
  solrad = get_solrad(in_UTC)
  times  = anytim(in_UTC, /tai)
  if not keyword_set(quiet) then print,"Computing signal arm A..."
  compute_sas_expected_signal,xoff,yoff,solrad,0, aperfile, sigA, dx=dx
  if not keyword_set(quiet) then print,"Computing signal arm B..."
  compute_sas_expected_signal,xoff,yoff,solrad,1, aperfile, sigB, dx=dx
  if not keyword_set(quiet) then print,"Computing signal arm C..."
  compute_sas_expected_signal,xoff,yoff,solrad,2, aperfile, sigC, dx=dx
  if not keyword_set(quiet) then print,"Computing signal arm D..."
  compute_sas_expected_signal,xoff,yoff,solrad,3, aperfile, sigD, dx=dx

  result = {signal:transpose([[sigA],[sigB],[sigC],[sigD]])/1.e9, times:times, utc:in_UTC, _calibrated:1}
  return, result
end
