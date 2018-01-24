;+
; :description:
;    This routine reads in the STX_PIXEL_DATA structure and
;    displays the status (count) of all pixels of all 30 detectors
;    for a given energy-bin at a given time
;    If a set of visibilities is passed in, two additional subplots are shown
;    with the visibility-amplitudes (with relativ phase) (plot 2)
;    and the phases of all 30 detectors (plot 3)
;    The pixel data [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ] is mapped as
;    |     |     |     |     |
;    |  1  |  2  |  3  |  4  |
;    |     |     |     |     |
;    -| 9|--|10|--|11|--|12|--
;    |     |     |     |     |
;    |  5  |  6  |  7  |  8  |
;    |     |     |     |     |
;    the Subcollimator data [0:31] is mapped as
;
;    1A 2A 3A 4A 5A 6A 7A 8A 9A 10A
;    1B 2B 3B 4B 5B 6B 7B 8B 9B 10B
;    1C 2C 3C 4C 5C 6C 7C 8C 9C 10C CFL BKG
;      
; :categories:
;    plotting, visualization
;
; :params:
;    pixel_data : in, required, type="stx_pixel_data"
;                 the stix pixel data structure
;    subc_str : in, required, type="stix subcollimator array" the file path
;               the stix subcollimator configuration structure (see stx_subc_params.txt)
;    t_index : in, required, type="long"
;              the time index (to pixel_data) to be plotted
;    e_index : in, required, type="long"
;              the energy index (to pixel_data) to be plotted
; :keywords:
;    visibility : in, type="stx_vis_cube", default="empty"
;               optional stx_visibility structure to be added to the plot
;    globalscale : in, type="bool [0|1]", default="0"
;               switch between using a global dynamic scale or local scales
;    ylog : in, type="bool [0|1]", default="0"
;               turn on/off the ylog in the visibility amplitude plot
;    sinfit : in, type="bool [0|1]", default="0"
;               turn on/off a sin fit to the pixel data deafult is off and a histogramm is shown
;    norm_small_pixel : in, type="double", default="1"
;               boost the small pixels in the visualisation   
;   showabcdratio in, type="bool [0|1]", default="0"
;               show the a+c=b+d dependency and top button redundancy 
;             
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
;     
; :todo:
;    28-Jan-2013, laszlo.etesi@fhnw.ch, open issues: finalize documentation, fix sine fitting, test propper sc placement, remove subc_str construction from the routine (create outside)
;                                                    implement a general detector and visibility sorting
;-
pro stx_plot_visibility_bag, vis_bag, dscale=dscale, ylog=ylog

  checkvar, ylog, 0
  
  if ~ppl_typeof(vis_bag, compareto='stx_visibility_bag') then begin
    plot, [0,2],[0,2],/nodata, position=[0,0,1,1]
    xyouts, 0.5,0.5, "No valid data found", charsize=3, color=255
    return
  end
  
  ; plot symbols
  ;symbols = make_array(7, 2, 3, /float)
  
  ;symbols[*,*,0] = [[0, 0, -0.5 , 0, 0.5, 0 ], [-1, 0, 0, 1, 0, 0]]
  ;symbols[*,*,1] = [[-1, 0, 0, 1, 0, 0] , [0, 0, -0.5 , 0, 0.5, 0 ]]
  ;symbols[*,*,2] = [[1, 0, 0, -1, 0, 0] , [0, 0, -0.5 , 0, 0.5, 0 ]]
  
  ;symbols[*,*,0] = [[-1, 0, -2 , 0, 1, 0, 2 ], [0, 0, 2, 0, 0, 0, -2]]     ;\
  ;symbols[*,*,1] = [[1, 0, 2 , 0, -1, 0, -2 ], [0, 0, 2, 0, 0, 0, -2]]     ;/
  ;symbols[*,*,2] = [[-1, 0, 0 , 0, 1, 0, 0 ], [0, 0, 2.8, 0, 0, 0, -2.8]]  ;|
  
  symbols = make_array(2, 2, 3, /float)
  symbols[*,*,0] = [[-2, 2 ], [2, -2]]     ;\
  symbols[*,*,1] = [[-2, 2 ], [-2, 2]]     ;/
  symbols[*,*,2] = [[0, 0 ], [2.8, -2.8]]  ;|
    
  
  
      
  ;BEGIN SORT DETECTOR AND VISIBILITY INPUT
    
    ; extract sorted pixel data indices (1a, 1b, 1c, 2a, etc.)
    ; natural sorting using bsort gives an incorrect order with 10a, 10b, 10c, 1a, etc.
    ; sorting below creates a new detector numbering starting a 0 going to 9. Detector number for bkg and cfl become -1
    ; joining with the labels (second half) allows for a new sorting with 0a, 0b, 0c, ..., -1bkg, -1cfl
    sorted_vis_idx = bsort(string((fix(stregex(vis_bag.visibility.label, '[0-9]+', /extr)) - 1)) + stregex(vis_bag.visibility.label, '[a-z]+', /extr))
    
    ;print, vis_bag.visibility.label
    ;print, vis_bag.visibility[sorted_vis_idx].label
    
    ; calculate visibility amplitudes and phases in sorted order
    vis_amplitudes = abs(vis_bag.visibility[sorted_vis_idx].obsvis)
    vis_phases = atan(vis_bag.visibility[sorted_vis_idx].obsvis, /phase)/!dtor
    
    x = findgen(22)
    y = fltarr(22)
    
    amplitude_range = n_elements(dscale) eq 2 ? dscale : minmax(vis_amplitudes)
    
    if amplitude_range[0] eq amplitude_range[1] then amplitude_range[1]++
    ; plot the amplidute chart
    plot, x, y, /nodata, xrange = [0,10], yrange=amplitude_range, POSITION = [0.1,0.55,1,0.95], $
          ycharsize = 1.5,xcharsize = 0.01, ytitle = "Visibility Amplitude", /xstyle, /ystyle, ylog=ylog, yticks=6
   
    ; plot each amplitude grouped by xA,B,C Detector
    for k=0,9 do begin
      for i=0,2 do begin
        multip = vis_phases[i * 10d + k] / 180.d
        
        ; plot markers for amplitude
        ; add a simple phase visualisation
        usersym, symbols[*,0,i], symbols[*,1,i]
        px=[k + 0.5d + (multip * 0.5d)]
        py=[vis_amplitudes[i * 10d + k]]
        oplot, px, py, psym=8, symsize=1
        oplot, px, py, psym=6, symsize=0.7
      endfor  
     
      ; plot vertical rulers
      oplot, [k, k], amplitude_range, linestyle=0, thick=2
      
      ; plot vertical center rulers
      oplot, [k + 0.5d, k + 0.5d], amplitude_range, linestyle=1, thick=1
      
    endfor
    datasource = tag_exist(vis_bag, "datasource") ? "DataSource: "+vis_bag.datasource : ""
    labels = make_array(21, /string, value=' ')
    labels[lindgen(10) * 2 + 1] = trim(lindgen(10) + 1)
    
    ; plot the phase chart
    plot, x, y, /noerase, linestyle=2, xrange=[0,20], yrange = [-180,180], /xstyle, /ystyle, POSITION=[0.1,0.15,1,0.55], $
      ycharsize=1.5, xcharsize=1.5, xtitle="Detector Units "+datasource, ytitle="Visibility Phase", $
      YTICKS=8, XTICKS=20, XTICKNAME = labels
      
    ; plot each phase grouped by xA,B,C Detector
    for k=0,9 do begin
      for i=0,2 do begin
        ; plot markers for phase
        usersym, symbols[*,0,i], symbols[*,1,i]
        px=[(0.5d + k)*2d]
        py=[vis_phases[i * 10d + k]]
        oplot, px, py, psym=8, symsize=1
        oplot, px, py, psym=6, symsize=0.7
      endfor
      ; plot vertical rulers
      oplot, [k * 2d, k * 2d], [-200,200], linestyle=0, thick=2
    endfor
  
end
