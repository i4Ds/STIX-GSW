;+
; :Categories:
;   STIX imaging and spectroscopy
;   
; :Name:
;   stx_livetime_fraction
;   
; :Examples:
;   livetime_fraction = stx_livetime_fraction( triggergram, det_select, tau_array = tau_array )
;
; :Categories:
;   STIX imaging and spectroscopy
;
; :Params:
;   triggergram - a structure of 16 x N trigger accumulations where N is the number of accumulated time intervals
;     may also be dimensioned to N trigger accumulations for a single detector
;    IDL> help, triggergram
;    ** Structure <131acfc0>, 4 tags, length=3264, data length=3264, refs=1:
;    TYPE            STRING    'stx_triggergram'
;    TRIGGERDATA     ULONG64   Array[16, 20] ;counts accumulated for each trigger for each time interval
;    ADG_IDX         INT       Array[16]  ;accumulator id's 1-16
;    T_AXIS          STRUCT    -> <Anonymous> Array[1];     stx time_axis structure
;   Det_select - sub-collimator numbers, 1-32
;   
; :Description:
;   28-Apr-13 gh
;
;  STIX Dead Time Correction Algorithm
;
;  The purpose of this writeup is to suggest an algorithm for the implementation of a STIX dead
;  time correction.
;
;  A careful description of the detector/ASIC performance that defines the form and approximate
;  parametrization can be found in xxxxx and yyyyy. The dead time correction will be primarily
;  applied on the ground, although a version may be needed for on-board correction in
;  conjunction with the coarse flare locator.
;
;  T = integration time during which counts were accumulated [known]
;  C = number of counts in the accumulator of interest (single pixel or pixel sum) [measured]
;  Cc = corrected number of counts in the accumulator of interest
;  D = number of counts in the corresponding live time accumulator, which counts triggers.
;  [measured]
;  Tau1 = nominal readout time [known]
;  Tau = (1+alpha)*tau1 = actual (or effective readout time) [assume exact value my not be
;  known a priori]
;  Eta1 = nominal latency time (coincidence window) [known]
;  Eta = (1+beta) * eta1 = actual (or effective readout time) [assume exact value may not be
;  known a priori] [depends on both energy of counts of interest and the spectrum]
;
;  Nin = number of incoming photons in the period of interest [not directly measured]
;
;  To be counted as a valid event in the accumulator of interest, an incoming photon must satisfy
;  two conditions.
;
;  First, it must initiate a trigger, the probability for which is defined as Pt.
;  This is the probability that no other readout was initiated in the previous Tau seconds.
;
;  D = Nin * Pt
;
;  Pt = exp(-D*tau/T)
;
;  Therefore
;
;  Or
;
;  Nin = D * exp(+D*tau/T)
;
;  D = Nin * exp (-Dtau/T)
;
;  Note that Nin depends on D, not C. Also, Nin increases monotonically with D. (or equivalently,
;  D increases monotonically with Nin)
;
;  The second condition is that if a trigger is initiated, no other photon must arrive in the
;  coincidence window, the probability for which is Ps. This is the probability that no other
;  photon arrived in the coincidence window.
;
;  C = Cc * Pt * Ps
;
;  Or Cc = C / Pt / Ps
;
;  Ps = exp(-Nin*eta/T)
;
;  ----------------------------------------------
;
;  Therefore the algorithm can be defined as follows:
;
;  Calculate Pt = exp (-D*tau/T)
;
;  Calculate Nin = D*exp (+D*tau/T)
;
;  Calculate Ps = exp (-Nin*eta/T)
;
;  Note that these calculations apply to any combination of pixels in a given detector pair.
;  Then for the accumulator(s) of interest, calculate
;
;  Cc = C / Pt /Ps
;  Initially, Tau is taken as 9.6 microseconds
;    Relation between STIX Event Count Rates and Live Time
;
;    Assumptions:    Readout time    6.6 us
;        Latency time    3 us
;
;    Counted Triggers  Probability Input photon rate Probability    Dead time      Reported
;    /s                of trigger  ph/s              of single hit  fraction       events/s/det
;
;    100               0.9993      100               0.9997          0.0010        50
;    1,000             0.9934      1,007             0.9970          0.0096        498
;    5,000             0.9675      5,168             0.9846          0.0473        2,462
;    10,000            0.9361      10,682            0.9685          0.0934        4,842
;    25,000            0.8479      29,485            0.9153          0.2239        11,442
;    50,000            0.7189      69,548            0.8117          0.4165        20,292  max operating point?
;    62,500            0.6620      94,412            0.7533          0.5013        23,542
;    80,000            0.5898      135,643           0.6657          0.6074        26,628
;    102,000           0.5101      199,971           0.5489          0.7200        27,992  max output rate
;    120,000           0.4529      264,937           0.4517          0.7954        27,100
;    150,000           0.3716      403,685           0.2979          0.8893        22,341
;    200,000           0.2671      748,684           0.1058          0.9717        10,582
;    300,000           0.1381      2,172,823         0.0015          0.9998        221
;
; :File_comments:
;   Uses a default Tau, deadtime per event, of 9.6 microseconds. This may need to
;   change based on tests of the Caliste detectors.
;   
; :Author:
;   richard.schwartz@nasa.gov
;   
; :History:
;   29-april-2013, created
;   18-april-2015, richard.schwartz@nasa.gov, major revision
;   03-dec-2018,   ECMD (Graz), change of calculation including eta and tau
;   03-mar-2022,   ECMD (Graz), update of eta and tau values and definition tau is now only readout time
;   21-apr-2022,   ECMD (Graz), added pileup correction parameter 
;   17-oct-2023,   ECMD (Graz), update of default eta value using empirical high trigger rate data 
;
;-
function stx_livetime_fraction, triggergram,  det_select, tau_array = tau_array,  eta_array=eta_array, error=error

  error = 1
  adg_sc = stx_adg_sc_table()
  default, det_select, indgen(32)+1

  ntrig  = (size(/dimension, triggergram.triggerdata ))[0]
  default, tau_array, 10.1e-6 + fltarr(ntrig) ;10.1 microseconds readout time per event
  default, eta_array, 1.10e-6 + fltarr(ntrig) ;1.1 microseconds latency time per event (best fit May 2023)

  beta = stx_pileup_corr_parameter() ; get estimate of pileup correction parameter 

  idx_select = ( adg_sc[ where_arr( adg_sc.sc, det_select ) ] ).adg_idx ;these are the agd id needed (1-16)
  test_triggers = where_arr( triggergram.adg_idx, idx_select, /notequal, test_forzero ) ;which triggers to use
  test_triggers = ~test_forzero ;this will be true for all needed triggers for det_select
  ;triggergram must be sorted into adg_idx order!
  ix_fordet = value_locate( triggergram.adg_idx, idx_select )

  ndt = n_elements( triggergram.t_axis.duration )
  duration = transpose( rebin( triggergram.t_axis.duration, ndt, ntrig ))
  tau_rate =   rebin( tau_array, ntrig, ndt ) / duration
  eta_rate = rebin( eta_array, ntrig, ndt ) / duration
  nin = triggergram.triggerdata / (1. -  triggergram.triggerdata *(tau_rate+eta_rate))
  livetime_fraction = exp( -1.*beta*eta_rate*nin) /(1. + (tau_rate+eta_rate)* nin)
  result = livetime_fraction[ ix_fordet[sort((where_arr( adg_sc.sc, det_select,/map ))[where_arr( adg_sc.sc, det_select)])], * ]
  error = 0
  return, result
  
end
