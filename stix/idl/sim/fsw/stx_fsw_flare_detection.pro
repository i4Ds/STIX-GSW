;+
; :description:
;    This procedure simulates the on board flare detection algo.
;    See https://www.dropbox.com/home/STIX/Instrument/Flight_Software/Algorithms/FSWflareDetectionAlgorithm20130701.docx for more infos and nomenclature
;
; :categories:
;    STIX, on board algo
;
; :parameters:
; 
;    quicklook_accumulated_data
;                     : in, type="uint(t,2)"
;                     the accumulated counts over time for the termal[0,t] and nonthermal[1,t] energy band
;                     
;    background       : in, type="uint(t,2)"
;                     the accumulated background counts over time for the termal[0,t] and nonthermal[1,t] energy band
;    
;    rate_control_state
;                     : in, type="byte(t)"
;                     attenuator state and pixel reduction
;                     
; :keywords:
;    kb               : in, type="float", default="1"
;                     background scaling factor for all energies and times
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
; :examples:
;    print, stx_fsw_flare_detection(/plotting)
;
; :history:
;    25-Feb-2014 - Nicky Hochmuth (FHNW), initial release
;    01-Feb-2016 - ECMD (Graz), kdk replaced with kdk_rise parameter, kdk_decay parameter added flare flag will now shut
;                               off if excess is less that kdk*peak or krel_decay*cbl
;    10-May-2016 - Laszlo I. Etesi (FHNW), updates due to structure changes
;    08-Mar-2017 - ECMD (Graz), replaced krel with krel_rise in plotting section 
;
;-
function stx_fsw_flare_detection, quicklook_accumulated_data, background, rate_control_state  $
    , nbl = nbl $
    , kb = kb $
    , thermal_kdk = thermal_kdk $
    , nonthermal_kdk = nonthermal_kdk $
    , thermal_krel_rise = thermal_krel_rise $
    , nonthermal_krel_rise = nonthermal_krel_rise $
    , thermal_krel_decay = thermal_krel_decay $
    , nonthermal_krel_decay = nonthermal_krel_decay $
    , thermal_cfmin = thermal_cfmin $
    , nonthermal_cfmin = nonthermal_cfmin $
    , flare_intensity_lut = flare_intensity_lut $
    , context = context $
    , int_time = int_time $ 
    , plotting = plotting $
    , ps = ps
  

  
  default, n_t,                         500
  default, quicklook_accumulated_data,  [[(sin(findgen(n_t)/40.0)+1)*120],[(sin((findgen(n_t)+3)/20.0)+2)*60]]
  
  
  default, nbl,                         [1200,60]
  default, thermal_cfmin,               [5,5]
  default, nonthermal_cfmin,            [30,30]
  default, thermal_kdk,                 [0.2,0.2]
  default, nonthermal_kdk,              [0.2,0.2]
  default, thermal_krel_rise,           [1.5,1.5]
  default, nonthermal_krel_rise,        [1.,1.] 
  default, thermal_krel_decay,          [0.5,0.5]
  default, nonthermal_krel_decay,       [0.5,0.5] 
  default, kb,                          30.
  default, int_time,                    4.
  default, plotting,                    1
  default, flare_intensity_lut,         [[100,200],[110,210],[120,220],[130,230]]
      
 
    
  kdk   = [thermal_kdk, nonthermal_kdk]
  cfmin = [thermal_cfmin, nonthermal_cfmin]
  krel_rise  = [thermal_krel_rise, nonthermal_krel_rise]
  krel_decay  = [thermal_krel_rise, nonthermal_krel_rise]

  
  n_time_nbl = nbl/int_time
  
  fip = bytarr(4)
  cbk = [.0,.0,.0,.0]
  
  n_time = n_elements(quicklook_accumulated_data)/2
  default, background,  [[indgen(n_time)/20],[indgen(n_time)/40]]
  
  if (size(background))[0] eq 1 then background = transpose(background) 
  
  ; for legacy purposes, allow both
  if keyword_set(context) && (ppl_typeof(context, compareto='stx_fsw_m_flare_detection_context') || ppl_typeof(context, compareto='stx_fsw_flare_detection_context')) then begin
    fip = context.fip
    cbk = context.cbk
    quicklook_accumulated_data = [[[context.thermal_cc],[context.nonthermal_cc]],quicklook_accumulated_data]
    n_time = n_elements(quicklook_accumulated_data)/2
    background = [[[context.thermal_bg],[context.nonthermal_bg]], background]
  end
  
  
  default, rate_control_state, bytarr(n_time)
  
  
  thermal_cc = quicklook_accumulated_data[*,0]
  thermal_cbc = thermal_cc - background[*,0] * kb
  lt0 = where(thermal_cbc lt 0, count_lt0)
  if count_lt0 gt 0 then thermal_cbc[lt0]=0
   
  nonthermal_cc = quicklook_accumulated_data[*,1]
  nonthermal_cbc = nonthermal_cc - background[*,1] * kb
  lt0 = where(nonthermal_cbc lt 0, count_lt0)
  if count_lt0 gt 0 then nonthermal_cbc[lt0]=0
     
  cbl = make_array(n_time,4,value=!VALUES.f_nan)
     
  flare_in_progress = make_array(n_time,4,value=!VALUES.f_nan)
  cbk_values = make_array(n_time,4,value=!VALUES.f_nan) 
  ce = make_array(n_time,4,value=!VALUES.f_nan)
     
  max_range = max(n_time_nbl[1],subscript_min=max_range_idx)

   for t=n_time_nbl[max_range_idx], n_time-1 do begin
      
      ;print,  t
      cbl[t,0]=median(thermal_cbc[t-n_time_nbl[0]:t])
      cbl[t,1]=median(thermal_cbc[t-n_time_nbl[1]:t])
      cbl[t,2]=median(nonthermal_cbc[t-n_time_nbl[0]:t])
      cbl[t,3]=median(nonthermal_cbc[t-n_time_nbl[1]:t])
   
      ce[t,*] = [thermal_cbc[t],thermal_cbc[t], nonthermal_cbc[t],nonthermal_cbc[t]]-cbl[t,*]
        
      ;set below zero values to zero
      bz = where(ce[t,*] lt 0, cbz)
      if cbz gt 0 then ce[t,bz]=0    
  
   
      ;if the attenuator is in place

      ;todo: check for past rate_control_states 
      ;if rate_control_state[t] gt 0 then begin
      if rate_control_state gt 0 then begin
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
          flare_still_on = (ce[t,ci] gt (cbk[ci] * kdk[ci])) OR  (ce[t,ci] gt (krel_decay[ci] * cbl[t,ci]))
        
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
            
            flare_turn_on =  $
              ;if ce is > than a minimum flare count 
              (ce[t,ci] gt cfmin[ci]) AND $
              ;if ce is > than Krel * Cbl
              (ce[t,ci] gt (krel_rise[ci] * cbl[t,ci]))
                 
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
  
  
  if plotting then begin
      
      if keyword_set(ps) then begin 
        ps_on, PAGE_SIZE=[9.8*2,12.5*2],paper="A3",/landscape, margin=0.5, filename="StixFlaredetectionSimulation.ps"
        !p.charsize=0.5
        !p.font=0
      
      end else begin
          window, xsize = 1250, ysize = 850, title="Stix Flaredetection Simulation"
        !p.charsize=1
      end
      
     cur_time_axis = lindgen(n_time)*int_time
     
     
     hsi_linecolors
        
     
     utplot, cur_time_axis, total(quicklook_accumulated_data,2), cur_time_axis[0], position=[0.12,0.75,0.88,0.98], xstyle=1, title="", ystyle=1, ytitle='', xcharsize=0.01, thick=3, yrange=[min(quicklook_accumulated_data),max(total(quicklook_accumulated_data,2))]
     outplot, cur_time_axis, quicklook_accumulated_data[*,0], cur_time_axis[0], linestyle=3
     outplot, cur_time_axis, quicklook_accumulated_data[*,1], cur_time_axis[0], linestyle=3
     
     plot_flare_in_progress = float(total(flare_in_progress,2,/nan) gt 0)
     ;set flare in prgogress = 0 to nan for plotting
     iz = where(plot_flare_in_progress eq 0, ciz)
     if ciz gt 0 then plot_flare_in_progress[iz]=!VALUES.f_nan
     plot_flare_in_progress_zero = plot_flare_in_progress
     plot_flare_in_progress_zero[where(plot_flare_in_progress ne 1)]=0
     
     utplot, cur_time_axis,  plot_flare_in_progress_zero ,  cur_time_axis[0], position=[0.12,0.06,0.88,0.98], yrange=[0.1,0.9], xstyle=5,ystyle=5, /noerase, title="", psym=10, linestyle=1
    
               
     ;plotting thermal band
     
     ;1 row: cc cbc cbl
     utplot, cur_time_axis, thermal_cc, cur_time_axis[0], position=[0.12,0.621667,0.88,0.73], xstyle=1, ystyle=9, /noerase,title="Thermal Band ",  xcharsize=0.01, linestyle=3, yrange=[1 , max([thermal_cc,background[*,0],thermal_cbc])], ylog=max(thermal_cc) gt 0
     outplot, cur_time_axis, background[*,0], cur_time_axis[0], color=3, linestyle=2
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
     outplot,cur_time_axis, cbl[*,0]*krel_rise[0] , cur_time_axis[0], linestyle=1, psym=10
     
     
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
     outplot, cur_time_axis, cbl[*,1]*krel_rise[1] , cur_time_axis[0],linestyle=1, psym=10
     
     ;flare in progress
     outplot, cur_time_axis, flare_in_progress[*,1]*2, cur_time_axis[0], color=3, thick=3, psym=10
     ;flux
     outplot, cur_time_axis, cbk_values[*,1], cur_time_axis[0],color=6
       
     ;plotting nonthermal band
     ;1 row: cc cbc cbl
     utplot, cur_time_axis, nonthermal_cc, cur_time_axis[0], position=[0.12,0.2767,0.88,0.385],ystyle=9, xstyle=1, /noerase,xcharsize=0.01, title="Nonthermal Band ",  linestyle=3, yrange=[1,max([nonthermal_cc,background[*,1],nonthermal_cbc])], ylog=max(nonthermal_cc) gt 0
     outplot, cur_time_axis, background[*,1], cur_time_axis[0], color=3,linestyle=2
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
     outplot, cur_time_axis, cbl[*,2]*krel_rise[2] , cur_time_axis[0],linestyle=1, psym=10
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
     outplot, cur_time_axis, cbl[*,3]*krel_rise[3] , cur_time_axis[0],linestyle=1, psym=10
     ;flare in progress
     outplot, cur_time_axis, flare_in_progress[*,3]*2, cur_time_axis[0], color=3, thick=3, psym=10
     ;flux
     outplot, cur_time_axis, cbk_values[*,3], cur_time_axis[0],color=6
     
    
     utplot, cur_time_axis, RATE_CONTROL_STATE, cur_time_axis[0],position=[0.12,0.75,0.88,0.98], yrange=[0,12], xstyle=5,ystyle=5, /noerase, color=6, title="",  xcharsize=0.01, thick=3
     outplot, [cur_time_axis[0],cur_time_axis[0]+nbl[0]], [7,7], cur_time_axis[0], color=5,thick=3
     xyouts, cur_time_axis[0],7.7,"     NBL 0 (s): "+trim(nbl[0]), color=5
     outplot, [cur_time_axis[0],cur_time_axis[0]+nbl[1]], [8.5,8.5], cur_time_axis[0], color=4,thick=3
     xyouts, cur_time_axis[0],8.7,"     NBL 1 (s): "+trim(nbl[1]), color=4
     xyouts, cur_time_axis[0],9.7,"     RCR", color=6
     xyouts, cur_time_axis[0],10.7,"     Flare", color=3
     
     outplot, cur_time_axis,  plot_flare_in_progress * 11 , cur_time_axis[0], color=3, thick=3, psym=10
     
     
     
     ;fake plot for legend
     utplot, 0,0, /nodata, /noerase, position=[0,0.05,0.12,0.34],ystyle=5, xstyle=5 
     al_legend, ["CC","Background","CBC","CBL NBL 0","CBL NBL 1","","","NBL 0","CE","CFmin","Krel*CBL","kdk*flux","Flare","","","NBL 1","CE","CFmin","Krel*CBL","kdk*flux","Flare"], colors=[0,3,6,5,4,1,1,1,5,0,0,6,3,1,1,1,4,0,0,6,3], linestyle=[3,2,0,0,0,0,0,0,0,2,1,0,0,0,0,0,0,2,1,0,0], /top, /left, box=0, linsize=1, margin=0
     
     
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
            " t NBL 0: "+trim(thermal_krel_rise[0]),$
            " t NBL 1: "+trim(thermal_krel_rise[1]),$
            "nt NBL 0: "+trim(nonthermal_krel_rise[0]),$
            "nt NBL 1: "+trim(nonthermal_krel_rise[1])]
     
    if keyword_set(ps) then begin
      ps_off
      !p.font=1
      !p.charsize=1
    end  
  endif;plotting

  
  if arg_present(context) then begin
    
    ; allow both for legacy purposes
    if ppl_typeof(context, compareto='stx_fsw_m_flare_detection_context') || ppl_typeof(context, compareto='stx_fsw_flare_detection_context') then begin
      past_n = n_elements(context.thermal_cc)
      flare_in_progress = flare_in_progress[past_n:-1,*]
      ce = ce[past_n:-1,*]
      n_time-=past_n
    end
    
    
    context_start = min([n_time_nbl[max_range_idx], n_elements(THERMAL_CC)])
    
    context = stx_fsw_m_flare_detection_context( $
      cbk=cbk, $
      thermal_cc=thermal_cc[-context_start:-1], $
      nonthermal_cc=nonthermal_cc[-context_start:-1], $
      fip=fip, $
      thermal_bg=background[-context_start:-1,0], $
      nonthermal_bg=background[-context_start:-1,1])
  endif 
  
  flare_flag = bytarr(n_time)
  
  for ci=0, 3 do begin
    flare_in_progress_idx = where(flare_in_progress[*,ci] gt 0, flare_in_progress_idx_count)
    if flare_in_progress_idx_count gt 0 then begin
      add = ishft(byte((value_locate(flare_intensity_lut[*,ci], ce[flare_in_progress_idx,ci]))+2),ci*2)
      flare_flag[flare_in_progress_idx]+=add
    endif
  endfor
   
  

  return, flare_flag
end
