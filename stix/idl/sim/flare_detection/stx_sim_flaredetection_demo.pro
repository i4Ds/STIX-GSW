;+
; :description:
;    This procedure simulates the on board flare detection algo.
;    See https://www.dropbox.com/home/STIX/Instrument/Flight_Software/Algorithms/FSWflareDetectionAlgorithm20130701.docx for more infos and nomenclature
;
; :categories:
;    STIX, on bord algo
;

; :keywords:
;     
;    nbl              : in, type="float(2)", default="[600,60]"
;                     seconds for the median window of 2 time series
;                     
;    thermal_kdk      : in, type="float(2)", default="[5%,5%]"
;                     relative Kdk factor for both time series for the thermal band
;               
;    nonthermal_kdk   : in, type="float(2)", default="[5%,5%]"
;                     relative Kdk factor for both time series for the nonthermal band
;
;    thermal_krel     : in, type="float(2)", default="[20%,20%]"
;                     relative Krel factor for both time series for the thermal band
;    
;    nonthermal_krel  : in, type="float(2)", default="[20%,20%]"
;                     relative Krel factor for both time series for the nonthermal band
;    
;    thermal_cfmin    : in, type="fix(2)", default="[100,10]"
;                     count threshold to turn on a flare for both time series in the thermal band
;                      
;    nonthermal_cfmin : in, type="fix(2)", default="[3,3]"
;                     count threshold to turn on a flare for both time series in the nonthermal band 
;    
;    thermalboundary  : in, type="double", default="25"
;                     the bandyra between thermal and nonthermal energy band in KeV
;                     
;    bk_nb_def        : in, type="double(32)", default="0..0"
;                     the default energy background before the examined time period
;
;    bk_na_def        : in, type="double(32)", default="0..0"
;                     the default energy background after the examined time period

;    use_default_bg   : in, type="bool", default="1"
;                     use the default background instet of real background from the rhessi db
;                     
;    secondperinterval: in, type="int", default="2h"
;                     seconds for a time period   
;    ps               : in, type="bool", default="0"
;                     turn on off post script output
;                     
; :examples:
;    stx_sim_flaredetection, /ps
;
; :history:
;    06-Sep-2013 - Nicky Hochmuth (FHNW), initial release
;
;-
pro stx_sim_flaredetection_demo $
    , nbl=nbl $
    , thermal_kdk = thermal_kdk $
    , nonthermal_kdk = nonthermal_kdk $
    , thermal_krel = thermal_krel $
    , nonthermal_krel = nonthermal_krel $
    , thermal_cfmin = thermal_cfmin $
    , nonthermal_cfmin = nonthermal_cfmin $
    , thermalboundary=thermalboundary $
    , bk_correction=bk_correction $
    , bk_nb_def=bk_nb_def $
    , bk_na_def = bk_na_def $
    , use_default_bg = use_default_bg $
    , secondperinterval = secondperinterval $
    , ps=ps
  
  ;time=anytim(['1-Aug-2002 00:00:00.000','31-Aug-2002 00:00:00.000'])  
  ;spg = stx_datafetch_rhessi2stix(time,50000, 30000,[4,4],histerese=0.5,/plot,file_name="stx_rhessi_model_crate_merge_07_08_2002.sav",local_path="D:\sswdb\rhessi2stix\",rate_control_state=rate_control_state)
  ;save, spg, rate_control_state, filename="d:\flare_detection.sav", /verbose
  
  search_network, /ena
  default, thermalboundary,        25.0
  default, nbl, [60*10,60]
  default, thermal_cfmin, [100,10]
  default, nonthermal_cfmin, [3,3]
  default, thermal_kdk, [0.05,0.05]
  default, nonthermal_kdk, [0.05,0.05]
  default, thermal_krel, [0.2,0.2]
  default, nonthermal_krel, [0.2,0.2] 
  default, bk_correction, make_array(32,value=0)
  default, bk_nb_def, transpose(make_array(32,value=0))
  default, bk_na_def, transpose(make_array(32,value=0))
  default, use_default_bg, 1
  default, secondperinterval, 60l*60*2 ;2h
  
  kdk = [thermal_kdk,nonthermal_kdk]
  cfmin = [thermal_cfmin,nonthermal_cfmin]
  krel = [thermal_krel,nonthermal_krel]
  
  energy_axis = stx_energy_axis()
  
  thermal_bands = where(energy_axis.mean lt thermalboundary,complement=nonthermal_bands) 
  
  starttime = anytim('2-Aug-2002 00:00:00.000')  
  endtime = anytim('31-Aug-2002 00:00:00.000')
  
  
  
  time_extension = max(nbl)
  
  real_secondperinterval = secondperinterval + time_extension 
  
  restore, filename=ppl_search_file("flare_detection_simulation_data.sav",descend=1), /verbose
  
  time_axis = spg->get(/time)
  
  n_time = real_secondperinterval/4
  n_energy = n_elements(energy_axis.mean)
  
  n_time_nbl = nbl/4 
  

  spg_data = spg->get(/spectro)
  if keyword_set(ps) then begin 
    ps_on, PAGE_SIZE=[9.8*2,12.5*2],paper="A3",/landscape, margin=0.5, filename="StixFlaredetectionSimulation.ps"
    !p.charsize=0.5
    !p.font=0
    
  end else begin
    window, xsize = 1250, ysize = 980, title="Stix Flaredetection Simulation"
    !p.charsize=1
  end
  
  ;starttime+=secondperinterval*2
  
  for i=0, 50 do begin
      ; Do some error handling
      error = 0
      catch, error
      if (error ne 0) then begin
        catch, /cancel
        err = err_state() 
        message, err, /continue
        error = 0
        starttime += secondperinterval
        destroy, obs_na
        destroy, obs_nb
        destroy, cur_spg
        destroy, bk_nb
        destroy, bk_na
      endif
     
  
     
     time_idx = where(time_axis ge starttime-max(nbl) AND time_axis lt starttime+secondperinterval)
     time_idx = where(time_axis ge starttime-max(nbl) AND time_axis lt starttime+secondperinterval)
     
     cur_time_axis = time_axis[time_idx]
     
     if ~use_default_bg then begin
     
       orbit_time = hsi_as_getorbit(cur_time_axis[0]-(24d*60*60))
       night_before = [orbit_time[0]-100, orbit_time[0]]
    
       orbit_time = hsi_as_getorbit(cur_time_axis[-1]+(24d*60*60))
       night_after = [orbit_time[1], orbit_time[1]+100]
    
       obs_nb = hsi_obs_summary(obs_time_interval=night_before)
       data = obs_nb->getdata(/corrected)
    
       obs_na = hsi_obs_summary(obs_time_interval=night_after)
       data = obs_na->getdata(/corrected)
       
       bk_nb = hsi_spectrum(obs_time=night_before,sp_energy_binning = energy_axis.edges_1,sp_data_structure=1,sp_data_unit = 'rate')
       bk_na = hsi_spectrum(obs_time=night_after,sp_energy_binning = energy_axis.edges_1,sp_data_structure=1,sp_data_unit = 'rate')
       
       bk_nb_data = n_elements(bk_nb->getdata()) eq 1 ? bk_nb_def : transpose(mean((bk_nb->getdata()).rate,dimension=2)) * bk_correction
       bk_na_data = n_elements(bk_na->getdata()) eq 1 ? bk_na_def : transpose(mean((bk_na->getdata()).rate,dimension=2)) * bk_correction
     
     end else begin
       bk_nb_data = bk_nb_def 
       bk_na_data = bk_na_def  
     end
       
     slope = double(bk_na_data-bk_nb_data)/(cur_time_axis[0]-cur_time_axis[-1])
     bg_spg = rebin(bk_nb_data,n_time,n_energy) - (rebin(cur_time_axis,n_time,n_energy)-cur_time_axis[0]) * rebin(slope,n_time,n_energy)
     
     
     
     loadct, 39
     
     if keyword_set(ps) then begin
      loadct, 8
      TVLCT, r, g, b, /Get
      TVLCT, Reverse(r), Reverse(g), Reverse(b)
     end
     
     ;spectrogramm plot
     cur_spg = make_spectrogram(spg_data[time_idx,*],time_axis=cur_time_axis,spectrum_axis=energy_axis.mean)
     cur_spg_data = cur_spg->get(/spectro)
    
     cur_spg->plot, position=[0.12,0.75,0.88,0.98], xstyle=1, title="", ystyle=1, ytitle='', /ylog, xcharsize=0.01, xaxis=5, yaxis=5, cbar=0, /log_scale
     
     hsi_linecolors
     
     if keyword_set(ps) then  axis,0.12, /yaxis,/ylog, /normal, yrange=[4,145], ystyle=1, /ynozero
     
     ;plot thermal bandary
     oplot, [cur_time_axis[0],cur_time_axis[-1]], [thermalboundary,thermalboundary], linestyle=1, thick=1 
     
     if ~use_default_bg then begin
        obs_nb->plot, dim1_colors=indgen(20)+1, /flare, /night, /attenuator, /corrected, legend_loc=0, position=[0.02,0.75,0.12,0.98], xstyle=1, /noerase, title="before bg", ystyle=1, xcharsize=0.001
        obs_na->plot, dim1_colors=indgen(20)+1, /flare, /night, /attenuator, /corrected, legend_loc=0, position=[0.88,0.75,0.98,0.98], xstyle=1, /noerase, title="after bg", ystyle=1, xcharsize=0.001, ytitle=""
     end
     
     yrange_spectrum = minmax([bk_nb_data,bk_na_data])
     
     ;plot the before background spectrum
     plot, energy_axis.mean, bk_nb_data, /xlog, xstyle=1, linestyle=0, /noerase, position=[0.02,0.405,0.12,0.73], title="bg spectrum",yrange=yrange_spectrum
     ;overplot the interpolated before background spectrum 
     oplot, energy_axis.mean, bg_spg[0,*], psym=2, color=3, symsize=0.5
     
     ;plot the after background spectrum
     plot, energy_axis.mean, bk_na_data, /xlog, xstyle=1, linestyle=0, /noerase, position=[0.88,0.405,0.98,0.73], title="bg spectrum",yrange=yrange_spectrum
     ;overplot the interpolated after background spectrum
     oplot, energy_axis.mean, bg_spg[-1,*], psym=2, color=3, symsize=0.5
     
     
     thermal_cc = total(cur_spg_data[*,thermal_bands],2,/double)
     thermal_bg = total(bg_spg[*,thermal_bands],2)
     thermal_cbc = thermal_cc-thermal_bg
     lt0 = where(thermal_cbc lt 0, count_lt0)
     if count_lt0 gt 0 then thermal_cbc[lt0]=0
     
     nonthermal_cc = total(cur_spg_data[*,nonthermal_bands],2,/double)
     nonthermal_bg = total(bg_spg[*,nonthermal_bands],2)
     nonthermal_cbc = nonthermal_cc-nonthermal_bg
     lt0 = where(nonthermal_cbc lt 0, count_lt0)
     if count_lt0 gt 0 then nonthermal_cbc[lt0]=0
     
     cbl = make_array(n_time,4,value=!VALUES.f_nan)
     
     flare_in_progress = make_array(n_time,4,value=!VALUES.f_nan)
     cbk_values = make_array(n_time,4,value=!VALUES.f_nan) 
     ce = make_array(n_time,4,value=!VALUES.f_nan)
     
     max_range = max(n_time_nbl[1],subscript_min=max_range_idx)
     
     fip = bytarr(4)
     cbk = [.0,.0,.0,.0]
     
     
     
     for t=n_time_nbl[max_range_idx], n_time-1 do begin
        
        cbl[t,0]=median(thermal_cbc[t-n_time_nbl[0]:t])
        cbl[t,1]=median(thermal_cbc[t-n_time_nbl[1]:t])
        cbl[t,2]=median(nonthermal_cbc[t-n_time_nbl[0]:t])
        cbl[t,3]=median(nonthermal_cbc[t-n_time_nbl[1]:t])
     
        ce[t,*] = [thermal_cbc[t],thermal_cbc[t], nonthermal_cbc[t],nonthermal_cbc[t]]-cbl[t,*]
          
        ;set below zero values to zero
        bz = where(ce[t,*] lt 0, cbz)
        if cbz gt 0 then ce[t,bz]=0    

     
        ;if the attenuator is in place
        if (rate_control_state[time_idx])[t] gt 0 then begin
          flare_in_progress[t,*] = 1 
          fip[*] = 1
          
          cbk = ceil(max([[cbk],[reform(ce[t,*])]],dimension=2))
          
          cbk_values[t,*] = cbk * kdk
          
          continue
        end
        
        for ci=0, 3 do begin
          if fip[ci] then begin
            ;update the flux maximum
            cbk[ci] = ce[t,ci] gt cbk[ci] ? ceil(ce[t,ci]) : cbk[ci]
            cbk_values[t,ci] = ([thermal_kdk,nonthermal_kdk])[ci] * cbk[ci]
          
            ;if ce is greater than cpk *kdk
            flare_still_on = ce[t,ci] gt (cbk[ci] * kdk[ci])
          
            if flare_still_on then begin 
              fip[ci]=1
              flare_in_progress[t,ci] = 1
            endif else begin
              fip[ci] = 0
              ;reset flux
              cbk[ci] = 0
              if ci eq 0 then begin
                ;print, "b"
              endif
              flare_in_progress[t,ci] = !VALUES.f_nan 
            end
            continue;
          ;if no flare is in progress
          endif else begin
              
              if (t gt 1000) && (ci eq 2) && (ce[t,ci] gt 4) then begin
                ;print, "te"
              end 
              
              flare_turn_on =  $
                ;if ce is > than a minimum flare count 
                (ce[t,ci] gt cfmin[ci]) AND $
                ;if ce is > than Krel * Cbl
                (ce[t,ci] gt (krel[ci] * cbl[t,ci]))
                   
              if flare_turn_on then begin
                fip[ci]=1
                flare_in_progress[t,ci] = 1 
                ;set the flux
                cbk[ci] = ceil(ce[t,ci])
              ;flare stays off
              endif else begin
                fip[ci] = 0
                ;reset flux
                cbk[ci] = 0
                flare_in_progress[t,ci] = !VALUES.f_nan
              end 
          endelse
        end ;loop ci
     end; loop time


     plot_flare_in_progress = float(total(flare_in_progress,2,/nan) gt 0)
     ;set flare in prgogress = 0 to nan for plotting
     iz = where(plot_flare_in_progress eq 0, ciz)
     if ciz gt 0 then plot_flare_in_progress[iz]=!VALUES.f_nan
     plot_flare_in_progress_zero = plot_flare_in_progress
     plot_flare_in_progress_zero[where(plot_flare_in_progress ne 1)]=0
     
     utplot, cur_time_axis,  plot_flare_in_progress_zero ,  cur_time_axis[0], position=[0.12,0.06,0.88,0.98], yrange=[0.1,0.9], xstyle=5,ystyle=5, /noerase, title="", psym=10, linestyle=1
    
               
     ;plotting thermal band
     
     ;1 row: cc cbc cbl
     utplot, cur_time_axis, thermal_cc, cur_time_axis[0], position=[0.12,0.621667,0.88,0.73], xstyle=1, ystyle=9, /noerase,title="Thermal Band "+trim(energy_axis.edges_1[0])+" - "+trim(thermalboundary)+"keV",  xcharsize=0.01, linestyle=3, yrange=[1 , max([thermal_cc,thermal_bg,thermal_cbc])], /ylog
     outplot, cur_time_axis, thermal_bg, cur_time_axis[0], color=3, linestyle=2
     outplot, cur_time_axis, thermal_cbc, cur_time_axis[0], color=6, thick=1
     outplot, cur_time_axis, cbl[*,0], cur_time_axis[0], color=5, thick=1
     outplot, cur_time_axis, cbl[*,1], cur_time_axis[0], color=4, thick=1
     
     ;2 row
     
     yrange=minmax(ce[*,0],/nan)
     yrange=minmax([yrange,thermal_cfmin[0]])
     yrange[0] = 1
     
     ;ce
     utplot, cur_time_axis, ce[*,0], cur_time_axis[0],color=5, position=[0.12,0.513334,0.88,0.621667], xstyle=1, ystyle=9, /noerase, xcharsize=0.01, yrange=yrange, /ylog
     ;cfmin threshold
     outplot, [cur_time_axis[0],cur_time_axis[-1]], make_array(2,value=thermal_cfmin[0]), cur_time_axis[0],linestyle=2
     outplot,cur_time_axis, cbl[*,0]*krel[0] , cur_time_axis[0], linestyle=1, psym=10
     
     
     ;flare in progress
     outplot, cur_time_axis, flare_in_progress[*,0]*2, cur_time_axis[0], color=3, thick=3, psym=10
     ;flux
     outplot, cur_time_axis, cbk_values[*,0], cur_time_axis[0], color=6
     
     ;3 row: 
     yrange=minmax(ce[*,1],/nan)
     yrange=minmax([yrange,thermal_cfmin[1]])
     yrange[0] = 1
     
     ;ce
     utplot, cur_time_axis, ce[*,1], cur_time_axis[0], color=4, position=[0.12,0.405,0.88,0.513334], xstyle=1, ystyle=9, /noerase, xcharsize=0.01, yrange=yrange, /ylog
     ;cfmin threshold
     outplot, [cur_time_axis[0],cur_time_axis[-1]], make_array(2,value=thermal_cfmin[1]), cur_time_axis[0], linestyle=2
     outplot, cur_time_axis, cbl[*,1]*krel[1] , cur_time_axis[0],linestyle=1, psym=10
     
     ;flare in progress
     outplot, cur_time_axis, flare_in_progress[*,1]*2, cur_time_axis[0], color=3, thick=3, psym=10
     ;flux
     outplot, cur_time_axis, cbk_values[*,1], cur_time_axis[0],color=6
       
     ;plotting nonthermal band
     ;1 row: cc cbc cbl
     utplot, cur_time_axis, nonthermal_cc, cur_time_axis[0], position=[0.12,0.2767,0.88,0.385],ystyle=9, xstyle=1, /noerase,xcharsize=0.01, title="Nonthermal Band "+trim(thermalboundary)+" - "+trim(energy_axis.edges_1[-1])+"keV",  linestyle=3, yrange=[1,max([nonthermal_cc,nonthermal_bg,nonthermal_cbc])], /ylog
     outplot, cur_time_axis, nonthermal_bg, cur_time_axis[0], color=3,linestyle=2
     outplot, cur_time_axis, nonthermal_cbc, cur_time_axis[0], color=6, thick=1
     outplot, cur_time_axis, cbl[*,2], cur_time_axis[0], color=5
     outplot, cur_time_axis, cbl[*,3], cur_time_axis[0], color=4
     
      ;2 row
     yrange=minmax(ce[*,2],/nan)
     yrange=minmax([yrange,nonthermal_cfmin[0]])
     yrange[0] = 1
     
     ;ce
     utplot, cur_time_axis, ce[*,2], cur_time_axis[0],color=5, position=[0.12,0.1684,0.88,0.2767], xstyle=1, ystyle=9, /noerase, xcharsize=0.01, yrange=yrange, /ylog
     ;cfmin threshold
     outplot, [cur_time_axis[0],cur_time_axis[-1]], make_array(2,value=nonthermal_cfmin[0]), cur_time_axis[0],linestyle=2
     outplot, cur_time_axis, cbl[*,2]*krel[2] , cur_time_axis[0],linestyle=1, psym=10
     ;flare in progress
     outplot, cur_time_axis, flare_in_progress[*,2]*2, cur_time_axis[0], color=3, thick=3, psym=10
     ;flux
     outplot, cur_time_axis, cbk_values[*,2], cur_time_axis[0], color=6
     
     
     ;3 row: 
     yrange=minmax(ce[*,3],/nan)
     yrange=minmax([yrange,nonthermal_cfmin[1]])
     yrange[0] = 1
     ;ce
     utplot, cur_time_axis, ce[*,3], cur_time_axis[0], color=4, position=[0.12,0.06,0.88,0.1684], xstyle=1, ystyle=9, /noerase, xcharsize=1.5, yrange=yrange, /ylog
     ;cfmin threshold
     outplot, [cur_time_axis[0],cur_time_axis[-1]], make_array(2,value=nonthermal_cfmin[1]), cur_time_axis[0], linestyle=2
     outplot, cur_time_axis, cbl[*,3]*krel[3] , cur_time_axis[0],linestyle=1, psym=10
     ;flare in progress
     outplot, cur_time_axis, flare_in_progress[*,3]*2, cur_time_axis[0], color=3, thick=3, psym=10
     ;flux
     outplot, cur_time_axis, cbk_values[*,3], cur_time_axis[0],color=6
     
    
     utplot, cur_time_axis, RATE_CONTROL_STATE[time_idx], cur_time_axis[0],position=[0.12,0.75,0.88,0.98], yrange=[0,12], xstyle=5,ystyle=5, /noerase, color=6, title="",  xcharsize=0.01, thick=3
     outplot, [cur_time_axis[0],cur_time_axis[0]+nbl[0]], [7,7], cur_time_axis[0], color=5,thick=3
     xyouts, cur_time_axis[0],7.7,"     NBL 0 (s): "+trim(nbl[0]), color=5
     outplot, [cur_time_axis[0],cur_time_axis[0]+nbl[1]], [8.5,8.5], cur_time_axis[0], color=4,thick=3
     xyouts, cur_time_axis[0],8.7,"     NBL 1 (s): "+trim(nbl[1]), color=4
     xyouts, cur_time_axis[0],9.7,"     RCR", color=6
     xyouts, cur_time_axis[0],10.7,"     Flare", color=3
     
     outplot, cur_time_axis,  plot_flare_in_progress * 11 , cur_time_axis[0], color=3, thick=3, psym=10
     
     
     
     ;fake plot for legend
     utplot, 0,0, /nodata, /noerase, position=[0,0.05,0.12,0.34],ystyle=5, xstyle=5 
     al_legend, ["CC","Background","CBC","CBL NBL 0","CBL NBL 1","","","NBL 0","CE","CFmin","Krel*CBL","kdk*flux","Flare","","","NBL 1","CE","CFmin","Krel*CBL","kdk*flux","Flare"], colors=[1,3,6,5,4,0,0,0,5,0,0,6,3,0,0,0,4,0,0,6,3], linestyle=[3,2,0,0,0,0,0,0,0,2,1,0,0,0,0,0,0,2,1,0,0], /top, /left, box=0, linsize=1, margin=0
     
     
     ;fake plot for parameters
     utplot, 0,0, /nodata, /noerase, position=[0.88,0.05,1,0.31],ystyle=5, xstyle=5, margin=0, linsize=0
     al_legend, /top,box=0,/left, $
          [ "KDK","=========",$
            " t NBL 0: "+trim(thermal_kdk[0]),$
            " t NBL 1: "+trim(thermal_kdk[1]),$
            "nt NBL 0: "+trim(nonthermal_kdk[0]),$
            "nt NBL 1: "+trim(nonthermal_kdk[1])]
            
     al_legend, /bottom,box=0,/left, $
          [ "KREL","=========",$
            " t NBL 0: "+trim(thermal_krel[0]),$
            " t NBL 1: "+trim(thermal_krel[1]),$
            "nt NBL 0: "+trim(nonthermal_krel[0]),$
            "nt NBL 1: "+trim(nonthermal_krel[1])]
     
     if ~keyword_set(ps) then begin
        print, "next intervall: (q)uit "
        a = GET_KBRD(/ESCAPE)
        if a eq 'q' then break
     end
        
     starttime += secondperinterval
     destroy, obs_na
     destroy, obs_nb
     destroy, cur_spg
     destroy, bk_nb
     destroy, bk_na
     
     print, "next time intervall"
     
  endfor
  
  
   print, "End"
   if keyword_set(ps) then begin
    ps_off
    !p.font=1
    !p.charsize=1
   end  
end