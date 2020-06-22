;+
; :Description:
;    Converts the temperature sensor adc value to a temperature in degrees Celsius
;
; :Params:
;    adc - reported sensor value 0-4094
;
;
;
; :Author: rschwartz70@gmail.com, 30-apr-2020
; Thanks to Ewan Dickson for giving me the code
;-
function stx_temp_convert, adc
  a1 =9.27e-4

  a2 =2.34e-4

  a3 = 9.09e-7

  a4 =1.04e-7

  x = alog(12000.*adc/(4095-adc))

  t = 1/(a1 + a2*x +a3*x^2. + a4*x^3) -273.15
  return, t
  end