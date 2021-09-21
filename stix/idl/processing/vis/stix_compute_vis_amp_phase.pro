
;+
;
; NAME:
;   stix_display_countrate
;
; PURPOSE:
;   Display the contrate of the event. In red, time interval considered
;
;-
pro stix_display_countrate, elist, tlist, time_spec, rspec_all, rspec_all_bkg, range_title

  stix_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
                                    l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
                                    res32,res10,o32,g03_10,g01_10,g_plot,l_plot

  ;plot to display what range was selected
  this_e=3
  loadct,5
  window,2,xsize=520,ysize=400
  clearplot
  if n_elements(elist) ne 1 then begin
    utplot,time_spec,total(total(total(rspec_all(*,g01_10,*,elist),4),3),2),psym=10,ytitle='STIX count rate [s!U-1!N]',title=range_title
    outplot,time_spec,time_spec*0.+total(rspec_all_bkg(0,g01_10,*,elist)),color=166
    outplot,time_spec(tlist),total(total(total(rspec_all(tlist,g01_10,*,elist),4),3),2),psym=10,color=122
  endif else begin
    utplot,time_spec,total(total(rspec_all(*,g01_10,*,elist),3),2),psym=10,ytitle='STIX count rate [s!U-1!N]',title=range_title
    outplot,time_spec,time_spec*0.+total(rspec_all_bkg(0,g01_10,*,elist)),color=166
    outplot,time_spec(tlist),total(total(rspec_all(tlist,g01_10,*,elist),3),2),psym=10,color=122
  endelse


end


;+
;
; NAME:
;   stix_display_moire_pattern
;
; PURPOSE:
;   For each detector, it displays the countrates registered by top row and bottom row pixels (red and blue respectively)
;
;-
pro stix_display_moire_pattern,this_r,this_rb,this_dr,range_title

  stix_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
                                      l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
                                      res32,res10,o32,g03_10,g01_10,g_plot,l_plot
  
  loadct,5
  window,0,xsize=900,ysize=800
  clearplot
  xmargin=0.08
  ymargin_top=0.12
  ymargin_bot=0.02
  xleer=0.02
  yleer=0.03
  xim=(1-2*xmargin-xleer)/6.
  yim=(1-ymargin_top-ymargin_bot-4*yleer)/5.
  c_top=122
  c_bot=44
  chs=1.0
  for i=0,29 do begin
    this_resolution=i/3
    this_row=i/6
    this_i=i-6*this_row
    if this_i ge 3 then this_space=xleer else this_space=0
    set_viewport,xmargin+this_i*xim+this_space,xmargin+(this_i+1)*xim+this_space,1-ymargin_top-(this_row+1)*yim-(this_row-1)*yleer,1-ymargin_top-this_row*yim-(this_row-1)*yleer
    this_title=l_plot(i)+'('+strtrim(fix(g_plot(i)),2)+');'+strtrim(fix(res32(g_plot(i))),2)+'";'+strtrim(fix(o32(g_plot(i))),2)+'!Uo!N'
    if i ne 24 then begin
      plot,[0.5,1.5,2.5,3.5],this_rb(g_plot(i),0:3),xtitle=' ',ytitle=' ',psym=-1,charsi=chs,yrange=[0,max(this_r(g_plot,0:7))],noe=i,xtickname=replicate(' ',9),ytickname=replicate(' ',9),xticks=8,xminor=1,xticklen=1d-22,title=this_title
      oplot,[0.5,1.5,2.5,3.5],this_rb(g_plot(i),0:3),psym=-1,color=c_top
      errplot,[0.5,1.5,2.5,3.5],(this_rb(g_plot(i),0:3)-this_dr(g_plot(i),0:3)),(this_rb(g_plot(i),0:3)+this_dr(g_plot(i),0:3)),thick=th3,color=c_top
      oplot,[0.5,1.5,2.5,3.5],this_rb(g_plot(i),4:7),psym=-1,color=c_bot
      errplot,[0.5,1.5,2.5,3.5],(this_rb(g_plot(i),4:7)-this_dr(g_plot(i),4:7)),(this_rb(g_plot(i),4:7)+this_dr(g_plot(i),4:7)),thick=th3,color=c_bot
    endif else begin
      plot,[0.5,1.5,2.5,3.5],this_rb(g_plot(i),0:3),xtitle=' ',ytitle='cts/s/keV',psym=-1,charsi=chs,yrange=[0,max(this_r(g_plot,*))],noe=i,xtickname=[' ','A',' ','B',' ','C',' ','D',' '],xticks=8,xminor=1,xticklen=1d-22,title=this_title
      oplot,[0.5,1.5,2.5,3.5],this_rb(g_plot(i),0:3),psym=-1,color=c_top
      errplot,[0.5,1.5,2.5,3.5],(this_rb(g_plot(i),0:3)-this_dr(g_plot(i),0:3)),(this_rb(g_plot(i),0:3)+this_dr(g_plot(i),0:3)),thick=th3,color=c_top
      oplot,[0.5,1.5,2.5,3.5],this_rb(g_plot(i),4:7),psym=-1,color=c_bot
      errplot,[0.5,1.5,2.5,3.5],(this_rb(g_plot(i),4:7)-this_dr(g_plot(i),4:7)),(this_rb(g_plot(i),4:7)+this_dr(g_plot(i),4:7)),thick=th3,color=c_bot
    endelse
  endfor
  xyouts,0.5,1-ymargin_top/2.5,range_title,/normal,chars=1.6,ali=0.5

end


;+
;
; NAME:
;   stix_display_amplutide_vs_resolution
;
; PURPOSE:
;   Plots the visibility amplitudes as a function of the subcollimator resolution
;
;-
pro stix_display_amplutide_vs_resolution, ampobs, sigamp

  stix_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
                                      l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
                                      res32,res10,o32,g03_10,g01_10,g_plot,l_plot
  
  color=122
  
  window,3,xsize=520,ysize=400,xpos=0,ypos=40
  clearplot
  ;shift display for bottom pixel to avoid overlap
  this_ff=1.1
  
  plot_oo,(1./res32)^2,ampobs,psym=1,xtitle='1/resolution^2',ytitle='amplitudes',yrange=[min(ampobs),max(ampobs+sigamp)],yst=1,/nodata,$
                      title='Visibility amplitudes vs resolution',xrange=[2d-5,1d-1],xsty=1
  oplot,(1./res32)^2,ampobs,psym=1,color=color,symsize=this_ss,thick=th3
  err_plot,(1./res32)^2,(ampobs-sigamp)>0.001,ampobs+sigamp,color=color,thick=th3,width=1d-13

end



;+
;
; NAME:
;   stix_compute_vis_amp_phase
;
; PURPOSE:
;   Extracts pixel data and computes visibility amplitudes and phases. Background subtraction and correction for live time and grid transmission are applied
;
; CALLING SEQUENCE:
;   data=stix_display_pixels_trans(sci_file,bkg_file,tr_flare,er_flare)
;
; INPUTS:
;  sci_file: path of the science L1 fits file
;  bkg_file: path of the background L1 fits file
;  tr_flare: array containing the start and the end of the time interval to consider
;  er_flare: array containing lower and upper bound of the energy range to consider
;  
;
; OUTPUTS:
;   structure containing pixel counts, visibility amplitudes and visibility phases
;
; KEYWORDS:
;   xy_flare: a priori estimate of the source location, needed for computing the transmission of the grids (heliocentric, north up)
;   no_trans: if set, not correction for grid trasmission is applied
;   pixels:   for choosing the pixels to use ('TOP', 'BOT', 'TOP-BOT')
;   silent:   if set, plots are not displayed
;         
;-
;-
FUNCTION stix_compute_vis_amp_phase,sci_file,bkg_file,tr_flare,er_flare,$
                                   xy_flare=xy_flare,no_trans=no_trans,pixels=pixels,silent=silent

;note: deadtime correction assumes 12.5d-6 and ignores double triggers (that is ok for the June 7 flare, but not necessarily for Nov 2020 flares)

  default, silent, 0
  default, pixels, 'TOP+BOT'

  stix_l1_read,sci_file,spec_all=spec_all,dspec_all=dspec_all,rspec_all=rspec_all,drspec_all=drspec_all,time_spec=time_spec,e0=e0,e1=e1,ee=ee,ddee=ddee
  
  ;data is now in the following variables
  ;SPEC_ALL        FLOAT     = Array[45, 32, 12, 32]  = [time, det, pix, energy]
  ;DSPEC_ALL       FLOAT     = Array[45, 32, 12, 32]
  ;RSPEC_ALL       FLOAT     = Array[45, 32, 12, 32]
  ;DRSPEC_ALL      FLOAT     = Array[45, 32, 12, 32]
  ;TIME_SPEC1      DOUBLE    = Array[45]
  ;E0              DOUBLE    = Array[32]
  ;E1              DOUBLE    = Array[32]
  ;EE              DOUBLE    = Array[32]

  ;background is taken after the flare
  stix_l1_read,bkg_file,spec_all=spec_all_bkg,dspec_all=dspec_all_bkg,rspec_all=rspec_all_bkg,drspec_all=drspec_all_bkg,time_spec=time_spec_bkg,time_dur=time_dur_bkg,e0=e0,e1=e1,ee=ee,ddee=ddee
  ;same format
  ;SPEC_ALL_BKG   FLOAT     = Array[1, 32, 12, 32] = [time, det , pix, energy]
  

  ; list of indices for time range
  tr_flare=anytim(tr_flare)
  tlist=where( (time_spec ge tr_flare(0)) AND (time_spec le tr_flare(1)) )
  ;same for energy range
  elist=where( (ee ge er_flare(0)) AND (ee le er_flare(1)) )
  ;title for plot
  if ~silent then range_title=strmid(anytim(tr_flare(0),/vms),0,11)+' '+strmid(anytim(tr_flare(0),/vms),12,8)+'-'+$
                              strmid(anytim(tr_flare(1),/vms),12,8)+'UT & '+strtrim(fix(er_flare(0)),2)+'-'+strtrim(fix(er_flare(1)),2)+' keV'


  ;ELUT
  ;correction should be done depending on the spectral shape
  ;here the lazy way: simply correct for actual bin size
  if tr_flare[1] lt anytim('1-Jan-2021 00:00:00') then begin
    f_elut = loc_file( 'elut_table_20200519.csv', path = getenv('STX_VIS_DEMO') )
  endif else if tr_flare[1] lt anytim('24-Jun-2021 00:00:00') then begin
    f_elut = loc_file( 'elut_table_20201204.csv', path = getenv('STX_VIS_DEMO') )
  endif else begin
    f_elut = loc_file( 'elut_table_20210625.csv', path = getenv('STX_VIS_DEMO') )
  endelse
  
  stx_read_elut, gain, offset, str4096, elut_filename = f_elut, scale1024=0, ekev_a = ekev
  ;ekev=[energy edges, pixel, det], only includes science energy bins, not 0 and last
  this_bin_low=reform(ekev(0:29,*,*))
  this_bin_high=reform(ekev(1:30,*,*))
  this_bin_size=this_bin_high-this_bin_low
  ;this_bin_size=[energy,pixel,det]
  ;THIS_BIN_SIZE   DOUBLE    = Array[30, 12, 32]
  ;rspec_all=[time, det, pix, energy]
  ;RSPEC_ALL       FLOAT     = Array[45, 32, 12, 32]
  this_bin_size_switch=fltarr(32,12,30)
  for i=0,29 do for j=0,11 do this_bin_size_switch(*,j,i)=this_bin_size(i,j,*)
  rspec_all_k=rspec_all
  drspec_all_k=drspec_all
  rspec_all_bkg_k=rspec_all_bkg
  for i=0,n_elements(time_spec)-1 do begin
    rspec_all_k(i,*,*,1:30)=rspec_all(i,*,*,1:30)/this_bin_size_switch
    drspec_all_k(i,*,*,1:30)=drspec_all(i,*,*,1:30)/this_bin_size_switch
  endfor
  rspec_all_bkg_k(0,*,*,1:30)=rspec_all_bkg(0,*,*,1:30)/this_bin_size_switch


  ;get rates  averaged over selected time and energy range: output = rate [det,pix]
  if n_elements(elist) eq 1 then begin
    this_r=average(rspec_all(tlist,*,*,elist),1)
    this_dr=sqrt(total(drspec_all(tlist,*,*,elist)^2,1))/(n_elements(tlist)*n_elements(elist))
    this_bkg=average(rspec_all_bkg(*,*,*,elist),1)
  endif else begin
    this_r=average(average(rspec_all(tlist,*,*,elist),4),1)
    this_dr=sqrt(total(total(drspec_all(tlist,*,*,elist)^2,4),1))/(n_elements(tlist)*n_elements(elist))
    this_bkg=average(average(rspec_all_bkg(*,*,*,elist),4),1)
  endelse
  
  ; Display countarate
  if ~silent then stix_display_countrate, elist, tlist, time_spec, rspec_all, rspec_all_bkg, range_title

  ;subtract background
  this_rb=this_r-this_bkg
  ;assume background subtraction is perfect
  this_drb=this_dr
  
  ;GRID TRANSMISSION
  if not keyword_set(no_trans) then begin 
    ;correct for measured grid transmission
    if not keyword_set(xy_flare) then begin 
      ;grid transmission normal incident (i.e. without grid shadowing) for flare location at center
      ;this_gtrans=stix_gtrans32_test([0,0.])
      this_gtrans=stix_gtrans32_test_sep_2021([0,0.])
    endif else begin
      ;for given flare location (note that finest grids are not corrected)
      ;this procedure needs to be double checked
      ;this_gtrans=stix_gtrans32_test(xy_flare)
      this_gtrans=stix_gtrans32_test_sep_2021(xy_flare)
    endelse
    ;apply grid correction
    for i=0,31 do begin
      this_r(i,*)=this_r(i,*)/this_gtrans(i)
      this_rb(i,*)=this_rb(i,*)/this_gtrans(i)
      this_drb(i,*)=this_drb(i,*)/this_gtrans(i)
    endfor
 endif
  
  ; indices for summing pixels
  case pixels of
    
  'TOP':     begin
             pixel_ind = [0]
             end
             
  'BOT':     begin
             pixel_ind = [1]
             end
  
  'TOP+BOT': begin
             pixel_ind = [0,1]
             end
             
  endcase
  
  ; Sum counts
  countrate = reform(this_rb, 32, 4, 3)
  countrate = n_elements( pixel_ind ) eq 1 ? reform(countrate[*, *, pixel_ind , *]) : total( countrate[*, *, pixel_ind, *], 3 )
  
  ; Compute count errors
  countrate_error = reform(this_drb, 32, 4, 3)
  countrate_error = n_elements( pixel_ind ) eq 1 ? reform(countrate_error[*, *, pixel_ind , *]) : sqrt(total( countrate_error[*, *, pixel_ind, *]^2, 3 ))
  
  ; Compute C-A and D-B
  vis_cmina = countrate(*,2) - countrate(*,0)
  vis_dminb = countrate(*,3) - countrate(*,1)  
  
  ; Compute errors on C-A and D-B  
  dcmina = sqrt( countrate_error(*,2)^2 + countrate_error(*,0)^2 )
  ddminb = sqrt( countrate_error(*,3)^2 + countrate_error(*,1)^2 )  
  
  ; Compute amplitudes
  ampobs = sqrt(vis_cmina^2+vis_dminb^2)
  
  ; Compute error on amplitudes
  syserr = 0.05
  sigamp = sqrt( ((vis_cmina)/ampobs*dcmina)^2+((vis_dminb)/ampobs*ddminb)^2 )
  sigamp = SQRT(sigamp^2  + syserr^2 * ampobs^2)
  
  ; Compute raw phases
  phase = atan(vis_dminb, vis_cmina) * !radeg
  
  ; Apply pixel correction
  phase += 46.1
  
  ; Grid correction factors
  phase_cal = read_csv(loc_file( 'GridCorrection.csv', path = getenv('STX_VIS_DEMO') ), header=header, table_header=tableheader)
  gcorr = phase_cal.field1
  ; Apply grid correction
  phase += gcorr
  
  ; Compute error on phases
  phase_error = sigamp/ampobs * !radeg
  
  out={amp: ampobs, $
    sigamp: sigamp, $
    phase: phase, $             ; in degrees
    phase_error: phase_error, $ ; in degrees
    rate_pixel: this_rb, $
    rate_pixel_error: this_drb, $
    tr_flare: tr_flare, $
    er_flare: er_flare}
  
  
  if ~silent then begin
    ; display observed moire pattern for each detector
    stix_display_moire_pattern,this_r,this_rb,this_dr,range_title
    
    ; display visibility amplitudes as a function of subcollimator resolution 
    stix_display_amplutide_vs_resolution, ampobs, sigamp
    
  endif
  
  return,out

END

