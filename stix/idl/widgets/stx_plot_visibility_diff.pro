;+
; :description:
;
;    If two sets of visibilities is passed in the fractional visibility amplitudes and the relative phase between each of the visibilities are plotted.
;
;
; :categories:
;    plotting, visualization
;
; :params:
;
;    vis_bag1 : in, required, type="stx_visibility_bag"
;                 the first visibility structure
;    vis_bag2 : in, required, type="stx_visibility_bag"
;                 the second visibility structure
;
; :keywords:
;
;    dscale  in, type ='float array'
;               if set then theses values are used as the maximum and minimum for the visibility amplitude plot
;
;    ylog :  in, type="bool [0|1]", default="0"
;               turn on/off the ylog in the visibility amplitude plot
;
;    oplot:  in, type="bool [0|1]", default="0"
;               if set the visibility comparison plots will be plotted over the previous plot
;               used if comparing multiple pairs of visibility bags
;
;    color:  in, type ='int', default="0"
;               colour index for the lines of both plots
;
;    lstyle: in, type ='int', default="0"
;                line style for the lines of both plots
;
; :examples:
;    pixel_data = ...
;    subc_str = stx_construct_subcollimator( )
;    stx_plot_pixel_data, pixel_data, subc_str, 0, 0
;
; :history:
;     25-Jul-2012, Version 1 written by Ines Kienreich (ines.kienreich@uni-graz.at)
;     30-Jul-2012, Version 2 written by Nicky Hochmuth (nicky.hochmuth@fhnw.ch)
;        clean up and integration to the stix framework
;        add axis - labels
;        add ylog
;        add globalscale
;        alter spacing
;     03-Aug-2012, removed color gradient filling for pixels and added /interpolate keyword, laszlo.etesi@fhnw.ch
;     29-Jan-2013, nicky.hochmuth@fhnw.ch, add a sorting to the detector and visibility input
;     04-Feb-2013, Shaun Bloomfield (TCD), modified visibility phase
;                  extraction to atan() of complex number (same as
;                  stx_visgen.pro) limited to -180 -> +180 degrees
;     01-Mar-2013, Nicky Hochmuth add a + c = b + d polar overplot
;     25-Oct-2013, Shaun Bloomfield (TCD), example text changed to
;                  stx_construct_subcollimator
;     10-Oct-2017, ECMD (Graz), initial release of stx_plot_visibility_diff based on stx_plot_visibility_bag
;
; :todo:
;    28-Jan-2013, laszlo.etesi@fhnw.ch, open issues: finalize documentation, fix sine fitting, test propper sc placement, remove subc_str construction from the routine (create outside)
;                                                    implement a general detector and visibility sorting
;-
pro stx_plot_visibility_diff, vis_bag1, vis_bag2, dscale=dscale, ylog=ylog, oplot = oplot , color = color, lstyle =  lstyle

  checkvar, ylog, 0
  
  if ~ppl_typeof(vis_bag1, compareto='stx_visibility_bag') then begin
    plot, [0,2],[0,2],/nodata, position=[0,0,1,1]
    xyouts, 0.5,0.5, "No valid data found", charsize=3, color=255
    return
  end
  
  ; plot symbols
  symbols = make_array(2, 2, 3, /float)
  symbols[*,*,0] = [[-2, 2 ], [2, -2]]     ;\
  symbols[*,*,1] = [[-2, 2 ], [-2, 2]]     ;/
  symbols[*,*,2] = [[0, 0 ], [2.8, -2.8]]  ;|
  
  
  
  ;BEGIN SORT DETECTOR AND VISIBILITY INPUT
  
  ; extract sorted pixel data indices (1a, 1b, 1c, 2a, etc.)
  ; natural sorting using bsort gives an incorrect order with 10a, 10b, 10c, 1a, etc.
  ; sorting below creates a new detector numbering starting a 0 going to 9. Detector number for bkg and cfl become -1
  ; joining with the labels (second half) allows for a new sorting with 0a, 0b, 0c, ..., -1bkg, -1cfl
  sorted_vis_idx = bsort(string((fix(stregex(vis_bag1.visibility.label, '[0-9]+', /extr)) - 1)) + stregex(vis_bag1.visibility.label, '[a-z]+', /extr))
  
  
  ; calculate visibility amplitudes and phases in sorted order for first bag
  vis_amplitudes1 = abs(vis_bag1.visibility[sorted_vis_idx].obsvis)
  vis_phases1 = atan(vis_bag1.visibility[sorted_vis_idx].obsvis, /phase)/!dtor
  
  
  ; calculate visibility amplitudes and phases in sorted order for second bag
  vis_amplitudes2 = abs(vis_bag2.visibility[sorted_vis_idx].obsvis)
  vis_phases2 = atan(vis_bag2.visibility[sorted_vis_idx].obsvis, /phase)/!dtor
  
  ;calculated difference in amplitudes and phases between the two bags
  vis_amplitudes = abs(vis_amplitudes1 - vis_amplitudes2)/vis_amplitudes1
  vis_phases = (vis_phases1 - vis_phases2)
  
  x = findgen(22)
  y = fltarr(22)
  
  amplitude_range = n_elements(dscale) eq 2 ? dscale : minmax(vis_amplitudes)*[0.9,1.1]
  
  if amplitude_range[0] eq amplitude_range[1] then amplitude_range[1]++
  ; plot the amplidute chart
  plot, x, y, /nodata, xrange = [0,10], yrange=amplitude_range, POSITION = [0.1,0.55,1,0.95], $
    ycharsize = 1.,xcharsize = 0.01, ytitle = "Fractional Amplitude Difference", /xstyle, /ystyle, ylog=ylog, yticks=6 ,noerase = oplot
    
  ; plot each amplitude grouped by xA,B,C Detector
  for k=0,9 do begin
    for i=0,2 do begin
      multip = vis_phases[i * 10d + k] / 180.d
      
      ; plot markers for amplitude
      ; add a simple phase visualisation
      usersym, symbols[*,0,i], symbols[*,1,i]
      px=[k + 0.5d + (multip * 0.5d)]
      py=[vis_amplitudes[i * 10d + k]]
      oplot, px, py, psym=8, symsize=1,color = color , linestyle = lstyle
      oplot, px, py, psym=6, symsize=0.7,color = color  , linestyle = lstyle
    endfor
    
    ; plot vertical rulers
    oplot, [k, k], amplitude_range, linestyle=0, thick=2
    
    ; plot vertical center rulers
    oplot, [k + 0.5d, k + 0.5d], amplitude_range, linestyle=1, thick=1
    
  endfor
  datasource = tag_exist(vis_bag1, "datasource") ? "DataSource: " + vis_bag1.datasource : ""
  labels = make_array(21, /string, value=' ')
  labels[lindgen(10) * 2 + 1] = trim(lindgen(10) + 1)
  
  ; plot the phase chart
  plot, x, y, /noerase, linestyle=2, xrange=[0,20], yrange = [-180,180], /xstyle, /ystyle, POSITION=[0.1,0.15,1,0.55], $
    ycharsize=1., xcharsize=1.5, xtitle="Detector Units " + datasource, ytitle="Phase Difference", $
    YTICKS=8, XTICKS=20, XTICKNAME = labels
    
  ; plot each phase grouped by xA,B,C Detector
  for k=0,9 do begin
    for i=0,2 do begin
      ; plot markers for phase
      usersym, symbols[*,0,i], symbols[*,1,i]
      px=[(0.5d + k)*2d]
      py=[vis_phases[i * 10d + k]]
      oplot, px, py, psym=8, symsize=1,color = color  , linestyle = lstyle
      oplot, px, py, psym=6, symsize=0.7,color = color  , linestyle = lstyle
    endfor
    ; plot vertical rulers
    oplot, [k * 2d, k * 2d], [-200,200], linestyle=0, thick=2
  endfor
  
end
