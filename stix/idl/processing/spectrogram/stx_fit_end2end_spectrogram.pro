;+
; :description:
; 
;    This procedure fits the time bins of an OSPEX spectrogram with the functions 'vth+1pow' for use with stx_end2end_spectrogram_test
;
; :categories:
;    data simulation, spectrogram
;
; :keywords:
;
;
; :examples:
;
;
; :history:
;
;       03-Dec-2018 – ECMD (Graz), initial release
;
;-
pro stx_fit_end2end_spectrogram,  obj, params, scenario_name= scenario_name, utvals =utvals, tntmask = tntmask

  obj-> set, spex_bk_sep = 0

  s = obj -> get(/spex_ut_edges)
  n_time_bins = floor((s[1,-2] - s[0,0])/4)
  n_time_bins = n_elements(utvals)
  time_edges = findgen(n_time_bins)*4.
  edge_products, utvals, edges_2 = time_intervals

  obj ->  set, spex_bk_time_interval= [[0,30], [[s[1,-1]-30,s[1,-1]]]]

  obj-> set, spex_fit_time_interval= time_intervals

  obj-> set, fit_function= 'vth+1pow'

  set_logenv, 'OSPEX_NOINTERACTIVE', '1'
  obj-> set, mcurvefit_itmax= 100L

  for k = 0, n_time_bins-1 do begin
    obj-> set, fit_comp_params= [1, 1.25366, 1.00000, 1e-4*tntmask[k,1] , 3.00000, 50.0000]
    obj-> set, fit_comp_minima= [1.00000e-20, 0.500000, 0.0100000, 1.00000e-10, 1.70000, $
      5.00000]
    obj-> set, fit_comp_maxima= [1.00000e+20, 8.00000, 10.0000, 1.00000e+10, 6.0000, 500.000]
    obj-> set, fit_comp_spectrum= ['full', '']
    obj-> set, fit_comp_model= ['chianti', '']
    obj-> set, spex_fit_start_method ='previous_start'
    obj->set, spex_fit_manual=0, spex_autoplot_enable=0, spex_fitcomp_plot_resid=0, spex_fit_progbar=0

    obj-> set, spex_erange=[4,150]
    obj-> set, spex_fit_auto_erange = 1
    obj-> set, fit_comp_free_mask= [1B, 1B, 0B, 0B, 0B, 0B]
    obj-> dofit,spex_intervals_tofit = k

    ee = obj-> get(/spex_erange)

    obj-> set, spex_erange=[ee[0],20]
    obj-> set, spex_fit_auto_erange = 0
    obj-> set, fit_comp_free_mask= [1B, 1B, 0B, 0B, 0B, 0B]
    obj-> dofit,spex_intervals_tofit = k

    fil = obj -> get(/spex_drm_current_filter)
    fil = fil < 1

    if tntmask[k,1] eq 1 then begin
      obj-> set, spex_erange=[20,ee[1]]
      obj-> set, spex_fit_auto_erange = 0
      obj-> set, fit_comp_free_mask= [0B, 0B, 0B, 1B, 1B, 0B]
      obj-> dofit,spex_intervals_tofit = k

      obj-> set, spex_erange=[4 +4*fil,ee[1]]
      ffcurr = obj->get(/fit_comp_params)

      obj-> set, fit_comp_free_mask= [1B, 1B, 0B, 1B,1B, 0B]
      obj-> dofit,spex_intervals_tofit = k

    endif else begin
      obj-> set, spex_erange=[4 +4*fil,ee[1]]
      obj-> set, spex_fit_auto_erange = 0
      obj-> set, fit_comp_free_mask= [1B, 1B, 0B, 0B,0B, 0B]
      obj-> dofit,spex_intervals_tofit = k

    endelse

    print,'done'

  endfor

  set_logenv, 'OSPEX_NOINTERACTIVE', '0'

  params = obj->get(/spex_summ_params)
  ospexfilename = filepath("ospex_obj.sav",root_dir=scenario_name)

  save, obj,filename = ospexfilename

end