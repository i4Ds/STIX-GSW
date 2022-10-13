;+
;
; NAME:
;
;   stx_plot_moire_pattern
;
; PURPOSE:
;
;   Plot Moire patterns from 'stx_pixel_data' structure
;
; CALLING SEQUENCE:
;
;   stx_plot_moire_pattern, pixel_data
;
; INPUTS:
;
;   pixel_data: 'stx_pixel_data' structure
;
; KEYWORDS:
;
;   no_small: if set, Moire patterns measured by small pixels are not plotted 
;
; HISTORY: September 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

pro stx_plot_moire_pattern, pixel_data, no_small=no_small

default, no_small, 0

;;******** Normalize counts_by live time, length of the considered energy interval and effective area

pixel_masks = pixel_data.PIXEL_MASKS
no_top = 0
no_bot = 0
if total(pixel_masks[0:3]) lt 4 then no_top = 1
if total(pixel_masks[4:7]) lt 4 then no_bot = 1
if total(pixel_masks[8:11]) lt 4 then no_small=1

counts       = pixel_data.COUNTS
counts_error = pixel_data.COUNTS_ERROR

;; livetime
live_time    = cmreplicate(pixel_data.LIVE_TIME, 12)
;; Effective area
subc_str = stx_construct_subcollimator()
eff_area = transpose(subc_str.DET.PIXEL.AREA)
;; Energy range
energy_range = pixel_data.ENERGY_RANGE
;; Compute rates (counts * s^-1 * cm^-2 * keV^-1)
counts_rates       = counts / (live_time * eff_area * (energy_range[1]-energy_range[0]))
counts_rates_error = counts_error / (live_time * eff_area * (energy_range[1]-energy_range[0]))

;;******** Plot rates

this_time_range = anytim(stx_time2any(pixel_data.TIME_RANGE), /vms)
this_date       = strmid(this_time_range[0],0,11)
this_start_time = strmid(this_time_range[0],12,8)
this_end_time   = strmid(this_time_range[1],12,8)

title = this_date + ' ' + this_start_time + '-' + this_end_time + ' UT, ' + $
  trim(energy_range[0],'(f12.1)') + '-' + trim(energy_range[1],'(f12.1)') + ' keV'

;; Indices and labels of the subcollimators
g10=[3,20,22]-1
l10=['10a','10b','10c']
g09=[16,14,32]-1
l09=['9a','9b','9c']
g08=[21,26,4]-1
l08=['8a','8b','8c']
g07=[24,8,28]-1
l07=['7a','7b','7c']
g06=[15,27,31]-1
l06=['6a','6b','6c']
g05=[6,30,2]-1
l05=['5a','5b','5c']
g04=[25,5,23]-1
l04=['4a','4b','4c']
g03=[7,29,1]-1
l03=['3a','3b','3c']
g02=[12,19,17]-1
l02=['2a','2b','2c']
g01=[11,13,18]-1
l01=['1a','1b','1c']

;; Subcollimator resolution
res32=fltarr(32)
res32(g10)=178.6
res32(g09)=124.9
res32(g08)=87.3
res32(g07)=61.0
res32(g06)=42.7
res32(g05)=29.8
res32(g04)=20.9
res32(g03)=14.6
res32(g02)=10.2
res32(g01)=7.1

;; Subcollimator grids' orientation
o32=intarr(32)
o32(g10)=[150,90,30]
o32(g09)=[170,110,50]
o32(g08)=[10,130,70]
o32(g07)=[30,150,90]
o32(g06)=[50,170,110]
o32(g05)=[70,10,130]
o32(g04)=[90,30,150]
o32(g03)=[110,50,170]
o32(g02)=[130,70,10]
o32(g01)=[150,90,30]

g_plot=[g10,g05,g09,g04,g08,g03,g07,g02,g06,g01]
l_plot=[l10,l05,l09,l04,l08,l03,l07,l02,l06,l01]

device, Window_State=win_state
if not win_state[0] then window,0,xsize=900,ysize=800
wset,0
loadct,39,/silent

clearplot

x_top_bot = [45,135,225,315]
x_small   = x_top_bot - 22.5

xmargin=0.08
ymargin_top=0.12
ymargin_bot=0.02
xleer=0.02
yleer=0.03
xim=(1-2*xmargin-xleer)/6.
yim=(1-ymargin_top-ymargin_bot-4*yleer)/5.
c_top=250
c_bot=198
c_small=70
chs=1.0
for i=0,29 do begin
  this_resolution=i/3
  this_row=i/6
  this_i=i-6*this_row
  if this_i ge 3 then this_space=xleer else this_space=0
  set_viewport,xmargin+this_i*xim+this_space,xmargin+(this_i+1)*xim+this_space,1-ymargin_top-(this_row+1)*yim-(this_row-1)*yleer,1-ymargin_top-this_row*yim-(this_row-1)*yleer
  this_title=l_plot(i)+'('+strtrim(fix(g_plot(i)),2)+');'+strtrim(fix(res32(g_plot(i))),2)+'";'+strtrim(fix(o32(g_plot(i))),2)+'!Uo!N'
  if i ne 24 then begin
    if ~no_top then begin
    plot,x_top_bot,counts_rates(g_plot(i),0:3),xtitle=' ',ytitle=' ',psym=-1,charsi=chs,yrange=[0,max(counts_rates(g_plot,*))],noe=i,xtickname=replicate(' ',9),ytickname=replicate(' ',9),xticks=8,xminor=1,xticklen=1d-22,title=this_title
    oplot,x_top_bot,counts_rates(g_plot(i),0:3),psym=-1,color=c_top
    errplot,x_top_bot,(counts_rates(g_plot(i),0:3)-counts_rates_error(g_plot(i),0:3)),(counts_rates(g_plot(i),0:3)+counts_rates_error(g_plot(i),0:3)),thick=th3,color=c_top
    endif
    if ~no_bot then begin
    if no_top then plot,x_top_bot,counts_rates(g_plot(i),4:7),xtitle=' ',ytitle=' ',psym=-1,charsi=chs,yrange=[0,max(counts_rates(g_plot,*))],noe=i,xtickname=replicate(' ',9),ytickname=replicate(' ',9),xticks=8,xminor=1,xticklen=1d-22,title=this_title
    oplot,x_top_bot,counts_rates(g_plot(i),4:7),psym=-1,color=c_bot
    errplot,x_top_bot,(counts_rates(g_plot(i),4:7)-counts_rates_error(g_plot(i),4:7)),(counts_rates(g_plot(i),4:7)+counts_rates_error(g_plot(i),*)),thick=th3,color=c_bot
    endif
    if ~no_small then begin
    if no_top and no_bot then plot,x_small,counts_rates(g_plot(i),8:11),xtitle=' ',ytitle=' ',psym=-1,charsi=chs,yrange=[0,max(counts_rates(g_plot,*))],noe=i,xtickname=replicate(' ',9),ytickname=replicate(' ',9),xticks=8,xminor=1,xticklen=1d-22,title=this_title
    oplot,x_small,counts_rates(g_plot(i),8:11),psym=-1,color=c_small
    errplot,x_small,(counts_rates(g_plot(i),8:11)-counts_rates_error(g_plot(i),8:11)),(counts_rates(g_plot(i),8:11)+counts_rates_error(g_plot(i),8:11)),thick=th3,color=c_small
    endif
  endif else begin
    if ~no_top then begin
    plot,x_top_bot,counts_rates(g_plot(i),0:3),xtitle=' ',ytitle='cts/s/keV/cm^2',psym=-1,charsi=chs,yrange=[0,max(counts_rates(g_plot,*))],noe=i,xtickname=[' ','A',' ','B',' ','C',' ','D',' '],xticks=8,xminor=1,xticklen=1d-22,title=this_title
    oplot,x_top_bot,counts_rates(g_plot(i),0:3),psym=-1,color=c_top
    errplot,x_top_bot,(counts_rates(g_plot(i),0:3)-counts_rates_error(g_plot(i),0:3)),(counts_rates(g_plot(i),0:3)+counts_rates_error(g_plot(i),0:3)),thick=th3,color=c_top
    endif
    if ~no_bot then begin
    if no_top then plot,x_top_bot,counts_rates(g_plot(i),4:7),xtitle=' ',ytitle='cts/s/keV/cm^2',psym=-1,charsi=chs,yrange=[0,max(counts_rates(g_plot,*))],noe=i,xtickname=[' ','A',' ','B',' ','C',' ','D',' '],xticks=8,xminor=1,xticklen=1d-22,title=this_title
    oplot,x_top_bot,counts_rates(g_plot(i),4:7),psym=-1,color=c_bot
    errplot,x_top_bot,(counts_rates(g_plot(i),4:7)-counts_rates_error(g_plot(i),4:7)),(counts_rates(g_plot(i),4:7)+counts_rates_error(g_plot(i),4:7)),thick=th3,color=c_bot
    endif
    if ~no_small then begin
    if no_top and no_bot then plot,x_small,counts_rates(g_plot(i),8:11),xtitle=' ',ytitle='cts/s/keV/cm^2',psym=-1,charsi=chs,yrange=[0,max(counts_rates(g_plot,*))],noe=i,xtickname=[' ','A',' ','B',' ','C',' ','D',' '],xticks=8,xminor=1,xticklen=1d-22,title=this_title
    oplot,x_small,counts_rates(g_plot(i),8:11),psym=-1,color=c_small
    errplot,x_small,(counts_rates(g_plot(i),8:11)-counts_rates_error(g_plot(i),8:11)),(counts_rates(g_plot(i),8:11)+counts_rates_error(g_plot(i),8:11)),thick=th3,color=c_small
    endif
  endelse
endfor

xyouts,0.5,1-ymargin_top/5.,title,/normal,chars=1.6,ali=0.5
xyouts,0.25,1-ymargin_top/2.2,'TOP ROW PIXELS',/normal,chars=1.6,ali=0.5, color=c_top
xyouts,0.5,1-ymargin_top/2.2,'BOTTOM ROW PIXELS',/normal,chars=1.6,ali=0.5, color=c_bot
if ~no_small then xyouts,0.75,1-ymargin_top/2.2,'SMALL PIXELS',/normal,chars=1.6,ali=0.5, color=c_small

end