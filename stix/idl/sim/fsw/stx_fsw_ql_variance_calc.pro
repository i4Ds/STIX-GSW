;+
; :description:
;  calculates count variance using data from quicklook accumulators
;
;  :categories:
;   quicklook, fsw
;
;  :params:
;   var_str:               in, required, type = 'structure'
;                          'stx_fsw_ql_variance' structure containing
;                          accumulated counts in 0.1 seconds summed over all
;                          pixels and the 30 Fourier detectors.
;
; :keywords:
;   no_var:                in, optional, type = 'unsigned long integer', default = 40,
;                          Number of 0.1 s accumulated intervals which the variance
;                          will be calculated over.
;
;  :returns:
;   var:                   the calculated variance/16 as an unsigned long integer where n is the
;                          total number of 0.1 x no_var time intervals.
;
;  :examples:
;   var=stx_fsw_ql_variance_calc(variance_str)
;
;  :history:
;   28-05-2014 - ECMD (GRAZ), initial release
;   18-06-2014 - ECMD (GRAZ), accumulator duration added as parameter taken from input structure rather than hard coded as 0.1
;   09-12-2016 - ECMD (GRAZ), implemented revised calculation as described in STIX-TN-0115-FHNW_i2r3_FSW_Variance_Calculation
;                             removed multiple quicklook time bin functionality expected input is now the counts in a single quicklook interval 
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), minor bugfix in padding routine at the beginning of the routine
;   28-Mar-2018 - Nicky Hochmuth (FHNW), add 16bit restriction, for instrument simulation
;-
function stx_fsw_ql_variance_calc, variance_str, no_var = no_var, bit16 = bit16

  default, no_var, 40ul
  default, bit16, 0
  
  ;extract array of accumulated counts
  counts = bit16 ? uint(variance_str.accumulated_counts) : ulong(variance_str.accumulated_counts)
  
  ;if number of intervals passed in is less than no_var pad the remainder with zeros
  if n_elements(counts) lt no_var then begin
    ;padding = ulonarr(no_var - n_elements(counts))
    ;counts = [counts, padding]
    s = size(counts)
    new_counts = ulonarr(s[1], s[2], s[3], 40)
    new_counts[*, *, *, 0:s[4]-1] = counts
    counts = new_counts
  endif
  
  ;if more than no_var variance accumulators are included in a quicklook interval
  ;use the first no_var so that interpretation remains consistent
  if n_elements(counts) gt no_var then counts = counts[0:no_var-1]
  
  ;calculate the mean value of the measured counts
  mean_counts = total(counts, /preserve_type)/no_var
  
  ;calculate the deviation from the mean and scale by a factor 4
  mean_deviation = long(counts - mean_counts)/4L
  
  ;calculation of variance/16
  variance = total( ulong(mean_deviation*mean_deviation), /preserve_type )
  
  return, variance
  
end
