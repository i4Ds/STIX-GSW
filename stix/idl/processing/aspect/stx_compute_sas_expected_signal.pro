;+
; Description :
;   This procedure computes the expected SAS signal for a given arm, given vectors of X/Y-offsets (in
;   the SAS frame) and solar radius as function of time,
;
; Category    : simulation / analysis
;
; Syntax      : stx_compute_sas_expected_signal, xoff, yoff, solrad, arm, signal
;
; Inputs      :
;   xoff/yoff = vectors (fn. of time) of Sun position in SAS frame [m]
;   solrad    = vector (fn. of time) of solar image radius [m]
;   arm       = integer number of arm for which to compute the signal (0=A, 1=B, 2=C, 3=D)
;
; Output      :
;   signal    = signal for given arm vs. time (N array)
;
; Keywords    :
;   dx        = linear step interval [m] - default: 1.e-6
;
; History     :
;   2020-01-31, F. Schuller (AIP) : created
;   2020-02-04, FSc : add conversion to nA
;   2020-02-05, FSc : make computation for one arm only
;   2020-06-18, FSc : removed roll angles (included in xoff, yoff)
;   2021-12-16, FSc : pass name (with absolute path) of file with description of apertures as argument
;
;-
pro stx_compute_sas_expected_signal, xoff, yoff, solrad, arm, aperfile, dx=dx, signal
  ; set default values for keywords
  if not keyword_set(dx) then dx = 1e-6   ; linear resolution for computation
  
  ; restore instrument specific constants
  restore, aperfile

  nap1=n_elements(apxtab1) & nap2=n_elements(apxtab2)
  nap3=n_elements(apxtab3) & nap4=n_elements(apxtab4)

  ; select apertures parameters for the requested arm
  if arm eq 0 then begin
    n_ap = nap1  &  x_ap = -1*apxtab1  &  y_ap = -1*apytab1  &  d_ap = d_ap1
  endif else if arm eq 1 then begin
    n_ap = nap2  &  x_ap = -1*apxtab2  &  y_ap = -1*apytab2  &  d_ap = d_ap2
  endif else if arm eq 2 then begin
    n_ap = nap3  &  x_ap = -1*apxtab3  &  y_ap = -1*apytab3  &  d_ap = d_ap3
  endif else if arm eq 3 then begin
    n_ap = nap4  &  x_ap = -1*apxtab4  &  y_ap = -1*apytab4  &  d_ap = d_ap4
  endif else begin
      print,"Don't know arm number ",arm
      print," ... exiting."
      stop
  endelse

  ; compute expected signal at each integration
  nbt = n_elements(xoff)
  signal  = fltarr(nbt)       ; total for requested arm
  for i = 0,nbt-1 do begin
   ; maxrange=solrad[i]*1.2     ; was *1.1, changed 2020-05-18
   ; maxrange=solrad[i]*1.3     ; changed again - 2020-10-06
    maxrange=solrad[i]*2.     ; changed again - 2021-10-08
    nx=maxrange/dx+1
    x_1d=(findgen(nx))/(nx-1.)*maxrange   ; 1D array of positions along which the solar profile is computed
    compute_solar_prof, x_1d, solrad[i], solprof, powcorr
      ; trying to add some background due to scattered light:
      ; compute_solar_prof, x_1d, solrad[i], solprof, powcorr, back=10.
    solprof = solprof[nx-1:*]          ; we need only a half-profile


    ; use same function as in stx_sim_sas_response
    ; but with /nointerpol to speed up computation (TO DO: optional argument)
    signal[i] = stx_sim_sas_signal_arm_circ_1d(xoff[i],yoff[i], d_ap, $
                              dx, x_ap, y_ap, x_1d, solprof, /nointerp)

    ; convert to current, in nA:
    currdens_image = 110.17313   ; current density at photodiode
    signal[i]  *= currdens_image * powcorr * 1e9
  endfor
end
