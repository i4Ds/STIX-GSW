;+
; Name: stx_mem_ge_percent_lambda
;
; Purpose: Get the value of the parameter 'percent_lambda' for the routine 'mem_ge' in the case of STIX data
;
; Method: computes the value of 'percent_lambda' as a function of the sigma Signal to Noise Ratio (SNR) for
;         a given visibility bag. The value of the parameters used in the function are set in order to obtain
;         a good regularization for stix data.
;
; Calling arguments:
;  snr_value -  value of the Signal to Noise Ratio (SNR) for a given visibility bag
;
; Output:
;   value of 'percent_lambda' used in the routine 'mem_ge'

function stx_mem_ge_percent_lambda, snr_value

  percent_lambda = 2./(snr_value^2. + 90.)

  return, percent_lambda

end

