;+
; :Description:
;    Plots the fractional differences in the fitted gain and offset between
;    the previous and current calibration spectra datasets
;
; :Params:
;    results
;    IDL> help, results
;        RESULTS         STRUCT    = -> STX_CAL_FITS Array[12, 32]
;        IDL> help, results,/st
;        ** Structure STX_CAL_FITS, 16 tags, length=64, data length=64:
;        E31             FLOAT           31.0541
;        E31S            FLOAT        0.00762761
;        R31             FLOAT           1.78836
;        R31S            FLOAT         0.0218994
;        E35             FLOAT           35.4279
;        E35S            FLOAT         0.0178856
;        R35             FLOAT           2.00855
;        R35S            FLOAT         0.0551651
;        E81             FLOAT           81.4295
;        E81S            FLOAT         0.0225141
;        R81             FLOAT           1.63080
;        R81S            FLOAT         0.0655710
;        GAIN_INPUT      FLOAT          0.430700
;        OFFSET_INPUT    FLOAT           263.748
;        GAIN_RESULT     FLOAT          0.428773
;        OFFSET_RESULT   FLOAT           263.900
;    dev_offset - dev_offset = r[*,i].offset_input/r[*,i].offset_result-1
;    dev_gain   - dev_gain   = r[*,i].gain_input/r[*,i].gain_result-1
;
;
;
;   Author: rschwartz70@gmail.com, 4-jul-2019
;-
pro stx_calib_fit_plot_change, results, dev_offset, dev_gain

  dev_offset = r[*,i].offset_input/r[*,i].offset_result-1
  dev_gain   = r[*,i].gain_input/r[*,i].gain_result-1

  !p.multi = [0,4,8]
  for i=0,31 do plot, psym=1, dev_offset, yrang=[-0.01,.01]

  for i=0,31 do plot, psym=1, dev_gain, yrang=[-0.01,.01]*2, ytitle='Gain Deviation'
  !p.multi = 0
end