pro stx_sim_create_ql_tc, conf  
  
  
  get_lun,lun
  openw, lun, "TC_237_9_QL.tcl"

  
  rcr     = conf->get(module="stx_fsw_module_rate_control_regime")
  global  = conf->get()
  bg      = conf->get(module="stx_fsw_module_background_determination")
  qla     = conf->get(module="stx_fsw_module_quicklook_accumulation")
  com     = conf->get(module="stx_fsw_module_tmtc") 
  dmo     = conf->get(module="stx_fsw_module_detector_monitor")
  fd      = conf->get(module="stx_fsw_module_flare_detection")
  cfl     = conf->get(module="stx_fsw_module_coarse_flare_locator")
  
  qld = stx_fsw_ql_accumulator_table2struct(qla.ACCUMULATOR_DEFINITION_FILE)

  printf, lun, 'source D:\\Tools\\scripts\\procedures.tcl'
  printf, lun, 'syslog "set ql params: tc(237,9)"'

  cmd = 'execTC "ZIX37009 '
  
;QL integration time
cmd += ' {PIX00520 ' + trim(fix(global.BASE_FREQUENCY) * 10)+ '}' 

bg_a = qld[where(qld.ACCUMULATOR eq "bkgd_monitor")]
ed = bytarr(33)
ed[*(bg_a.CHANNEL_BIN)]=1
DEFAULT_BACKGROUND = intarr(8)

DEFAULT_BACKGROUND[0:n_elements(bg.DEFAULT_BACKGROUND)-1] = bg.DEFAULT_BACKGROUND


;[BG] Number of QL iterations
cmd += ' {PIX00521 ' + trim(fix(bg.UPDATE_FREQUENCY / global.BASE_FREQUENCY)) + '}' 
;[BG] Energy bin edge mask – upper edge
cmd += ' {PIX00522 ' + trim(stx_mask2bits(ed[32])) + '}' 
;[BG] Energy bin edge mask – lower edges
cmd += ' {PIX00523 ' + trim(stx_mask2bits(ed[0:31])) + '}' 
;[BG] algorithm enabled flag
cmd += ' {PIX00524 1 }' 
;[BG] TM generation enabled flag
cmd += ' {PIX00525 Enabled }' 
;[BG] Default background in range 1
cmd += ' {PIX00526 ' + trim(DEFAULT_BACKGROUND[0]) + '}' 
;[BG] Default background in range 2
cmd += ' {PIX00527 ' + trim(DEFAULT_BACKGROUND[1]) + '}' 
;[BG] Default background in range 3
cmd += ' {PIX00528 ' + trim(DEFAULT_BACKGROUND[2]) + '}' 
;[BG] Default background in range 4
cmd += ' {PIX00529 ' + trim(DEFAULT_BACKGROUND[3]) + '}' 
;[BG] Default background in range 5
cmd += ' {PIX00530 ' + trim(DEFAULT_BACKGROUND[4]) + '}' 
;[BG] Default background in range 6
cmd += ' {PIX00531 ' + trim(DEFAULT_BACKGROUND[5]) + '}' 
;[BG] Default background in range 7
cmd += ' {PIX00532 ' + trim(DEFAULT_BACKGROUND[6]) + '}' 
;[BG] Default background in range 8
cmd += ' {PIX00533 ' + trim(DEFAULT_BACKGROUND[7]) + '}' 
;[BG] count compression scheme
cmd += ' {PIX00534 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_BACKGROUND_COMPRESSION_COUNTS))) + '}' 
;[BG] trigger compression scheme
cmd += ' {PIX00535 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_BACKGROUND_COMPRESSION_TRIGGERS))) + '}' 


lc_a = qld[where(qld.ACCUMULATOR eq "lightcurve")]
ed = bytarr(33)
ed[*(lc_a.CHANNEL_BIN)]=1
dm = bytarr(32)
pm = bytarr(12)
dm[*(lc_a.DET_INDEX_LIST)-1]=1
pm[*(lc_a.PIXEL_INDEX_LIST)]=1 

;[LC] number of QL integrations
cmd += ' {PIX00536 ' + trim(fix(qla.RESET_FREQUENCY_STX_FSW_QL_LIGHTCURVE / global.BASE_FREQUENCY)) + '}' 
;[LC] Energy bin edge mask – upper edge
cmd += ' {PIX00537 ' + trim(stx_mask2bits(ed[32])) + '}' 
;[LC] Energy bin edge mask – lower edges
cmd += ' {PIX00538 ' + trim(stx_mask2bits(ed[0:31])) + '}' 
;[LC] TM generation enabled flag
cmd += ' {PIX00539 Enabled }' 
;[LC] detector mask
cmd += ' {PIX00540 ' + trim(stx_mask2bits(dm)) + '}' 
;[LC] pixel mask
cmd += ' {PIX00541 ' + trim(stx_mask2bits(pm)) + '}' 
;[LC] count compression scheme
cmd += ' {PIX00542 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_LIGHT_CURVES_COMPRESSION_COUNTS))) + '}' 
;[LC] trigger compression scheme
cmd += ' {PIX00543 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_LIGHT_CURVES_COMPRESSION_TRIGGERS))) + '}' 


va_a = qld[where(qld.ACCUMULATOR eq "variance")]
em = bytarr(32)
emin = min(*(va_a.CHANNEL_BIN),MAX=emax)
em[emin+indgen(emax-emin)]=1

dm = bytarr(32)
pm = bytarr(12)
dm[*(va_a.DET_INDEX_LIST)-1]=1
pm[*(va_a.PIXEL_INDEX_LIST)]=1

;[VAR] detector mask
cmd += ' {PIX00544 ' + trim(stx_mask2bits(dm)) + '}' 
;[VAR] energy mask
cmd += ' {PIX00545 ' + trim(stx_mask2bits(em)) + '}' 
;[VAR] pixel mask
cmd += ' {PIX00546 ' + trim(stx_mask2bits(pm)) + '}' 
;[VAR] TM generation enabled flag
cmd += ' {PIX00547 Enabled }' 
;[VAR] variance compression scheme
cmd += ' {PIX00548 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_VARIANCE_SPECTRUM_COMPRESSION_COUNTS))) + '}'

sp_a = qld[where(qld.ACCUMULATOR eq "spectra")]
dm = bytarr(32)
pm = bytarr(12)
dm[*(sp_a.DET_INDEX_LIST)-1]=1
pm[*(sp_a.PIXEL_INDEX_LIST)]=1
 
;[SP] number of QL integrations
cmd += ' {PIX00549 ' + trim(fix(qla.RESET_FREQUENCY_STX_FSW_QL_SPECTRA / global.BASE_FREQUENCY)) + '}' 

;todo make dynamicly
cmd += ' {PIX00919 10 }' 

;[SP] TM generation enabled flag
cmd += ' {PIX00550 Enabled }' 
;[SP] pixel mask
cmd += ' {PIX00551 ' + trim(stx_mask2bits(pm)) + '}' 
;[SP] detector mask
cmd += ' {PIX00552 ' + trim(stx_mask2bits(dm)) + '}' 
;[SP] count compression scheme
cmd += ' {PIX00553 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_SPECTRA_COMPRESSION_COUNTS))) + '}' 
;[SP] trigger compression scheme
cmd += ' {PIX00554 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_SPECTRA_COMPRESSION_TRIGGERS))) + '}'


df_a = qld[where(qld.ACCUMULATOR eq "detector_anomaly")]
em = bytarr(32)
emin = min(*(df_a.CHANNEL_BIN),MAX=emax)
em[emin+indgen(emax-emin)]=1
 
;[DF] number of QL integrations
cmd += ' {PIX00555 ' + trim(fix(qla.RESET_FREQUENCY_STX_FSW_QL_DETECTOR_ANOMALY / global.BASE_FREQUENCY)) + '}' 
;[DF] energy mask
cmd += ' {PIX00556 ' + trim(stx_mask2bits(em)) + '}' 
;[DF] NBAD parameter
cmd += ' {PIX00557 ' + trim(dmo.NBAD < 15) + '}' 
;[DF] KBAD parameter
cmd += ' {PIX00558 ' + trim(dmo.KBAD < 15) + '}' 
;[DF] CBAD parameter
cmd += ' {PIX00559 ' + trim(dmo.RBAD < 2L^16) + '}' 
;[DF] NREP parameter = MBAD
cmd += ' {PIX00560 ' + trim(dmo.MBAD < 15) + '}' 


fd_a = qld[where(qld.ACCUMULATOR eq "flare_detection")]
dm = bytarr(32)
pm = bytarr(12)
dm[*(fd_a.DET_INDEX_LIST)-1]=1
pm[*(fd_a.PIXEL_INDEX_LIST)]=1

em = *(fd_a.CHANNEL_BIN)

em_t = bytarr(32)
em_t[em[0]+indgen(em[1]-em[0])]=1

em_nt = bytarr(32)
em_nt[em[2]+indgen(em[3]-em[2])]=1

;[FD] number of QL integrations
cmd += ' {PIX00561 ' + trim(fix(qla.RESET_FREQUENCY_STX_FSW_QL_FLARE_DETECTION / global.BASE_FREQUENCY)) + '}' 
;[FD] detector mask
cmd += ' {PIX00562 ' + trim(stx_mask2bits(dm)) + '}' 
;[FD] pixel mask
cmd += ' {PIX00563 ' + trim(stx_mask2bits(pm)) + '}' 
;[FD] thermal energy mask
cmd += ' {PIX00564 ' + trim(stx_mask2bits(em_t)) + '}' 
;[FD] non-thermal energy mask
cmd += ' {PIX00565 ' + trim(stx_mask2bits(em_nt)) + '}' 
;[FD] TM generation enabled flag
cmd += ' {PIX00566 Enabled }' 
;[FD] KB parameter
cmd += ' {PIX00567 30' + trim(fd.KB) + '}' 
;[FD] timescale 1 – RCR 0 count factor
cmd += ' {PIX00568 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 1 count factor
cmd += ' {PIX00569 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 2 count factor
cmd += ' {PIX00570 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 3 count factor
cmd += ' {PIX00571 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 4 count factor
cmd += ' {PIX00572 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 5 count factor
cmd += ' {PIX00573 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 6 count factor
cmd += ' {PIX00574 ' + trim(1) + '}' 
;[FD] timescale 1 – RCR 7 count factor
cmd += ' {PIX00575 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 0 count factor
cmd += ' {PIX00576 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 1 count factor
cmd += ' {PIX00577 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 2 count factor
cmd += ' {PIX00578 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 3 count factor
cmd += ' {PIX00579 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 4 count factor
cmd += ' {PIX00580 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 5 count factor
cmd += ' {PIX00581 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 6 count factor
cmd += ' {PIX00582 ' + trim(1) + '}' 
;[FD] timescale 2 – RCR 7 count factor
cmd += ' {PIX00583 ' + trim(1) + '}' 

;todo see: https://stix-so.slack.com/files/U9MRCGFEC/FB7B59WRZ/-.txt
;[FD] Cfmin variable
cmd += ' {PIX00584 1' + trim(1) + '}' 
;[FD] Krel variable
cmd += ' {PIX00585 1' + trim(1) + '}' 
;[FD] Krel-prime variable
cmd += ' {PIX00586 1' + trim(1) + '}' 
;[FD] Krel-double prime variable
cmd += ' {PIX00587 1' + trim(1) + '}' 
;[FD] timescale 1 history
cmd += ' {PIX00588 ' + trim(fd.Nbl[0]) + '}' 
;[FD] timescale 2 history
cmd += ' {PIX00589 ' + trim(fd.Nbl[1]) + '}' 
;[FD] initial thermal CBC value
cmd += ' {PIX00590 1' + trim(1) + '}' 
;[FD] initial non-thermal CBC value
cmd += ' {PIX00591 1' + trim(1) + '}' 
;[FD] threshold for thermal B1 flare
cmd += ' {PIX00592 1' + trim(1) + '}' 
;[FD] threshold for thermal C1 flare
cmd += ' {PIX00593 1' + trim(1) + '}' 
;[FD] threshold for thermal M1 flare
cmd += ' {PIX00594 1' + trim(1) + '}' 
;[FD] threshold for thermal X1 flare
cmd += ' {PIX00595 1' + trim(1) + '}' 
;[FD] threshold for weak non-thermal flare
cmd += ' {PIX00596 1' + trim(1) + '}' 
;[FD] threshold for strong non-thermal flare
cmd += ' {PIX00597 1' + trim(1) + '}' 


cfl_a = qld[where(qld.ACCUMULATOR eq "flare_location_1")]
em = bytarr(32)
em_ch = *(cfl_a.CHANNEL_BIN)
em[em_ch[cfl.ENERGY_BAND]+indgen(em_ch[cfl.ENERGY_BAND+1]-em_ch[cfl.ENERGY_BAND])]=1

dm = bytarr(32)
dm[*(cfl_a.DET_INDEX_LIST)-1]=1

;[FL] number of integrations
cmd += ' {PIX00598 ' + trim(fix(qla.RESET_FREQUENCY_STX_FSW_QL_FLARE_LOCATION_1 / global.BASE_FREQUENCY)) + '}' 
;[FL] detector mask
cmd += ' {PIX00599 ' + trim(stx_mask2bits(dm)) + '}' 
;[FL] energy mask
cmd += ' {PIX00600 ' + trim(stx_mask2bits(em)) + '}' 
;[FL] V1 variable
cmd += ' {PIX00601 ' + trim(CFL.LOWER_LIMIT_COUNTS) + '}' 
;[FL] V2 variable
cmd += ' {PIX00602 ' + trim(CFL.UPPER_LIMIT_COUNTS) + '}' 
;[FL] K variable
cmd += ' {PIX00603 ' + trim(CFL.out_of_range_factor < 2L^8-1) + '}' 
;[FL] K-prime variable
cmd += ' {PIX00604 ' + trim(CFL.tot_bk_factor) + '}' 
;[FL] K-double prime variable
cmd += ' {PIX00605 ' + trim(CFL.quad_bk_factor) + '}' 
;[FL] K-triple prime variable
cmd += ' {PIX00606 ' + trim(CFL.cfl_bk_factor) + '}' 
;[FL] K0 variable
cmd += ' {PIX00607 ' + trim(ceil(CFL.normalisation_factor[0])) + '}' 
;[FL] K1 variable
cmd += ' {PIX00608 ' + trim(ceil(CFL.normalisation_factor[1])) + '}' 
;[FL] K2 variable
cmd += ' {PIX00609 ' + trim(ceil(CFL.normalisation_factor[2])) + '}' 

tab_data = stx_cfl_read_skyvec(cfl.CFL_LUT, sky_x = sky_x, sky_y = sky_y)

;[FL] Dx
cmd += ' {PIX00610 ' + trim(sky_x[1]-sky_x[0]) + '}' 
;[FL] Dy
cmd += ' {PIX00611 ' + trim(sky_y[1]-sky_y[0]) + '}' 
      
      
  cmd += '" '

  printf,lun, cmd


  free_lun, lun
  
  get_lun,lun
  openw, lun, "TC_237_11_CS.tcl"
  
  printf, lun, 'syslog "set compression schema: tc(237,11)"'


  cmd = 'execTC "ZIX37011 {PIX00813 0} {PIX00814 False} {PIX00815 False} {PIX00816 255} {PIX00817 4294967295} {PIX00818 255} {PIX00819 255} {PIX00820 255} {PIX00821 255} {PIX00822 255} {PIX00823 255} {PIX00824 255} {PIX00825 255} {PIX00826 4294967295} {PIX00827 255} {PIX00828 255} {PIX00829 255} {PIX00830 255} {PIX00831 255} {PIX00832 255} {PIX00833 255} {PIX00834 255} {PIX00835 255} {PIX00836 255} {PIX00837 255} {PIX00838 255} {PIX00839 255} {PIX00840 255} {PIX00841 255} {PIX00842 255} {PIX00843 255} {PIX00844 255} {PIX00845 255} {PIX00846 255} {PIX00847 255} {PIX00848 255} {PIX00849 255} {PIX00850 255} {PIX00851 255} {PIX00852 255} {PIX00853 255} {PIX00854 255} {PIX00855 255} {PIX00856 255} {PIX00857 255} {PIX00858 255} {PIX00859 255} {PIX00860 255} {PIX00861 255} {PIX00862 255} {PIX00863 255} {PIX00864 255} {PIX00865 255} {PIX00866 255} {PIX00867 4294967295} {PIX00868 4080} {PIX00869 2184} {PIX00870 1092} {PIX00871 546} {PIX00872 273} {PIX00873 255} {PIX00874 255} {PIX00875 255} {PIX00876 255} {PIX00877 255} {PIX00878 255} {PIX00879 255} {PIX00880 255} {PIX00881 255} {PIX00882 255} {PIX00883 255} {PIX00884 255} {PIX00885 255} {PIX00886 255} {PIX00887 255} {PIX00888 255} {PIX00889 255} {PIX00890 255} {PIX00891 255} {PIX00892 255} {PIX00893 255} {PIX00894 255} {PIX00895 255} {PIX00896 255} {PIX00897 255} {PIX00898 255} {PIX00899 255} {PIX00900 255} {PIX00901 255} {PIX00902 255} {PIX00903 255} {PIX00904 255} {PIX00905 255} {PIX00906 255} {PIX00907 255} {PIX00908 4294967295} {PIX00909 29} {PIX00910 29} {PIX00911 29} {PIX00912 107} '
  
  ;Calibration compression scheme
  cmd += ' {PIX00913 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_CALIBRATION_SPECTRUM_COMPRESSION_COUNTS))) + '}'
  ;Variance compression scheme
  cmd += ' {PIX00914 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_VARIANCE_SPECTRUM_COMPRESSION_COUNTS))) + '}'
  ;Light curve counts compression scheme
  cmd += ' {PIX00915 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_LIGHT_CURVES_COMPRESSION_COUNTS))) + '}'
  ;QL spectrum counts compression scheme
  cmd += ' {PIX00916 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_SPECTRA_COMPRESSION_COUNTS))) + '}'
  ;BG monitor counts compression scheme
  cmd += ' {PIX00917 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_BACKGROUND_COMPRESSION_COUNTS))) + '}'
  ;Common QL Trigger accumulator compression scheme
  cmd += ' {PIX00918 ' + trim(fix(stx_km_compression_params_to_schema(config=com.QL_LIGHT_CURVES_COMPRESSION_TRIGGERS))) + '}'
  
  cmd += '" '

  printf,lun, cmd


  free_lun, lun
  
  
   

  
end