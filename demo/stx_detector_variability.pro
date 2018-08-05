pro stx_detector_variability, text = text, quiet = quiet
  which,'stx_detector_variability',outfile=outfile
  text = rd_ascii( outfile)
  ntext = n_elements( text )
  default, quiet, 0
  if ~quiet then  for i = 6, ntext-1 do print, text[i]
  ;
  ;Simulate spatially integrated detector efficiency with simulated variabilty.
  ;Examine some considerations as to when/how to use variability
  ;There are two main considerations that we take from the RHESSI heritage
  ;Case 1. A detector loses overall sensitivity. To be determined from comparing spatially integrated
  ;counts, ie summing over pixel sets A, B, C, and D
  ;For a permanent loss of overall sensitivity, compare the total counts. If the difference is statistically significant
  ;and consistent over time then implement a correction term in the response.  Here we will test for statistical
  ;significance in simulated variations. We'll use a total counts per detector of 100,000 and look for differences gt 5 sigma
  ;
  ;IDL> out = stx_normalize_demo( normalize = 100000.)
  ;% Program caused arithmetic error: Floating underflow
  ;IDL> cts = out.sim_counts
  ;IDL> help, cts
  ;CTS             FLOAT     = Array[32, 100, 4, 30]
  ;IDL> out.readme
  ;;  In out.sim_counts, 32 count bins, 100 spectral shape bins,
  ;; 4 bins for thrm-att0, thrm-att1, pow-att0, pow-att1
  ;; thermal range, 1-3 keV Temp, pl range 2-8 single powerlaw exponent
  ;; 30 sub- with randomized efficiency deviations
  ;Other functions may be exchanged for default spectra
  ;using th_flux_model and nt_flux_model keywords, ie. nt for non-thermal
  ;IDL> cts1 = cts[*,20, 3, *]
  ;IDL> help, cts1
  ;CTS1            FLOAT     = Array[32, 1, 1, 30]
  ;IDL> cts1 = reform( cts[*,20, 3, *])
  ;IDL> help, out
  ;** Structure <2048c550>, 15 tags, length=10767840, data length=10767810, refs=1:
  ;SIM_COUNTS      FLOAT     Array[32, 100, 4, 30]
  ;EDG2            FLOAT     Array[2, 32]
  ;SIM_DETVAR      FLOAT     Array[30, 600]
  ;PH_EDG          FLOAT     Array[2, 600]
  ;DRM0            STRUCT    -> <Anonymous> Array[1]
  ;DRM1            STRUCT    -> <Anonymous> Array[1]
  ;SEED_POI_IN     INT           -999
  ;SEED_SCL_IN     INT           -999
  ;SEED_COEF_IN    INT           -999
  ;PLAW_EXP        FLOAT     Array[100]
  ;TKEV            FLOAT     Array[100]
  ;NTFLUX          FLOAT     Array[600, 100]
  ;THFLUX          FLOAT     Array[600, 100]
  ;NORMALIZE       FLOAT           100000.
  ;README          STRING    Array[6]
  ;IDL> print, out.plaw_exp[20]
  ;3.21212
  ;IDL> help, cts1
  ;CTS1            FLOAT     = Array[32, 30]
  ;IDL> ;look for change in total efficiency
  ;IDL> print, reform(  total(cts1, 1) )
  ;96236.7      99699.6      96795.7      97831.4      100325.      105303.      98972.9      104389.      98548.1      101655.      103463.      101016.
  ;98131.4      101208.      98334.4      98837.5      103124.      100291.      98605.1      100695.      97380.5      96453.0      97358.9      105308.
  ;105751.      96471.3      98090.7      99715.6      102869.      97139.7
  ;IDL> ;Compute deviation from the average
  ;IDL> print, avg(  total(cts1, 1) )
  ;100000.
  ;IDL> avg_cts1 = avg(  total(cts1, 1) )
  ;IDL> ;What's the deviation?
  ;IDL> print, ( reform(  total(cts1, 1) ) - avg_cts1 )/ sqrt( avg_cts1)
  ;-11.9007    -0.949919     -10.1328     -6.85775      1.02846      16.7681     -3.24805      13.8806     -4.59133      5.23224      10.9517      3.21443
  ;-5.90906      3.81894     -5.26695     -3.67600      9.87826     0.920495     -4.41103      2.19759     -8.28349     -11.2166     -8.35182      16.7861
  ;18.1863     -11.1586     -6.03765    -0.899470      9.07297     -9.04500
  ;IDL> print, ( reform(  total(cts1, 1) ) - avg_cts1 )/ avg_cts1
  ;-0.0376334  -0.00300391   -0.0320427   -0.0216861   0.00325227    0.0530255   -0.0102713    0.0438942   -0.0145191    0.0165458    0.0346322    0.0101649
  ;-0.0186861    0.0120766   -0.0166555   -0.0116245    0.0312378   0.00291086   -0.0139489   0.00694937   -0.0261947   -0.0354702   -0.0264108    0.0530823
  ;0.0575101   -0.0352867   -0.0190927  -0.00284438    0.0286913   -0.0286028
  ;So we see that while there are a number of sub-collimators with significant deviations in response we might not want
  ;to make any corrections as they are no more than 5%. Before making any changes to the ground software, we'd want to see these difference
  ;reproduced over a number of different events observed at a number of locations in the imaging coordinate system
  ;Case 2.  Look for differences in the flux in a single energy channel across detectors and renormalize the visibilities so all
  ;spatial frequencies receive equal weight.  We have implemented this as a routine correction for RHESSI and the STIX team
  ;may also want to.  This is the basic outline of how to generate the appropriate correction for the calibrated visibilities. The scaling
  ;factors here will be applied multiplicatively to the stix obsvis terms
;  IDL> help, cts1
;  CTS1            FLOAT     = Array[32, 30]
;  IDL> ;Look at energy bin 20
;  IDL> print, reform( cts1[20,*])
;  3312.60      3435.14      3338.57      3371.81      3452.01      3631.96      3408.44      3594.48      3396.29      3507.92      3564.30      3485.97
;  3379.46      3490.64      3393.14      3407.43      3553.32      3457.99      3396.19      3473.52      3350.03      3328.01      3351.92      3632.38
;  3645.45      3325.28      3374.21      3430.73      3540.79      3348.13
;  IDL> ;Compute the average
;  IDL> a20 = avg( cts1[20,*])
;  IDL> print, a20
;  3445.94
;  IDL> ;compute the deviations from the average
;  IDL> print, reform( cts1[20,*]-a20)/ sqrt(a20)
;  -2.27135    -0.183989     -1.82896     -1.26280     0.103471      3.16894    -0.638835      2.53048    -0.845753      1.05581      2.01638     0.681897
;  -1.13241     0.761600    -0.899374    -0.655916      1.82938     0.205329    -0.847529     0.469835     -1.63373     -2.00885     -1.60167      3.17613
;  3.39870     -2.05542     -1.22181    -0.259121      1.61581     -1.66620
;  IDL> ;The largest deviation is more than 3 sigma but what is fractional difference?
;  IDL> print, reform( cts1[20,*]-a20)/ a20
;  -0.0386928  -0.00313428   -0.0311566   -0.0215120   0.00176265    0.0539834   -0.0108827    0.0431072   -0.0144075    0.0179859    0.0343493    0.0116162
;  -0.0192909    0.0129740   -0.0153210   -0.0111736    0.0311637   0.00349781   -0.0144378   0.00800372   -0.0278308   -0.0342211   -0.0272847    0.0541058
;  0.0578974   -0.0350143   -0.0208138  -0.00441417    0.0275256   -0.0283840
;  IDL> ;There's a difference of at most 6% from the average and ~10% between SCs. When we are making images we'll have to look at the consequences
;  IDL> ;of including this correction.  The reasons for and against are not the subject of this discussion.
;  IDL> ;Finally, compute the multiplicative correction factors
;
;  IDL> norm_factors = a20 / cts1[20,*] ;should be applied to the visibility complex amplitudes for all the visiblities for s given image
end