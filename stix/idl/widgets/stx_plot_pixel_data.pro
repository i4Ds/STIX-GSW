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
pro stx_plot_pixel_data, pixel_data, subc_str, visibility=visibility, dscale=dscale, ylog=ylog, sinfit=sinfit, norm_small_pixel=norm_small_pixel, showabcdratio=showabcdratio

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

  checkvar, norm_small_pixel, 1
  checkvar, ylog, 0
  default, showabcdratio, 0
  
  if n_elements(pixel_data) ne 1 || ~is_struct(pixel_data) || ~tag_exist(pixel_data,"counts")   then begin
    plot, [0,2],[0,2],/nodata, position=[0,0,1,1]
    message, "No valid data found", /continue
    xyouts, 0.5,0.5, "No valid data found", charsize=3, color=255
    return
  end
  
  dim = size(pixel_data.counts)
  
  ; number of detectors to show
  dts  =  dim[1]  
  
  
  ; number of pixels
  pxls =  dim[2]
  
  if pxls ne 12 && pxls ne 4 then begin
    plot, [0,2],[0,2],/nodata, position=[0,0,1,1]
    message, "No supported pixel format", /continue
    xyouts, 0.5,0.5, "No supported pixel format", charsize=3, color=255
    return
  end 
  
  summed = pxls eq 4
  
  ; frame_bp for big pixels
  frame_bp = ulon64arr(4, 2)
  
  ; frame_bp for small pixels
  frame_sp = ulon64arr(4)
  
  
  ;BEGIN SORT DETECTOR INPUT
    
    ; extract sorted pixel data indices (1a, 1b, 1c, 2a, etc.)
    ; natural sorting using bsort gives an incorrect order with 10a, 10b, 10c, 1a, etc.
    ; sorting below creates a new detector numbering starting a 0 going to 9. Detector number for bkg and cfl become -1
    ; joining with the labels (second half) allows for a new sorting with 0a, 0b, 0c, ..., -1bkg, -1cfl
    sorted_det_idx = bsort(string((fix(stregex(subc_str.label, '[0-9]+', /extr)) - 1)) + stregex(subc_str.label, '[a-z]+', /extr))
    
    pixel_data_copy = pixel_data.counts
    
    total_count = ulong64(0)
    
    for loop_var=0, dts-1 do begin ; detector loop
      ; the drawing routine requires the following detector sequence:
      ; 1a, 2a, 3a, 4a, ...
      ; 1b, 2b, 3b, 4b, ...
      ; 1c, 2c, 3c, 4c, ...
      ; cfl, bkg
      ; the line below translates the sorted detector indices (1a, 1b, 1c, 2a, 2b, 2c, ...)to the detector sequence required below 
      detect_i = sorted_det_idx[((loop_var * 3) mod 30) + (floor(loop_var / 10d))]
      
      ; special fix for cfl and bgk
      if(loop_var eq 30) then detect_i = where(subc_str.label eq 'cfl')
      if(loop_var eq 31) then detect_i = where(subc_str.label eq 'bkg')
      
      pixel_data.counts[loop_var,*] = pixel_data_copy[detect_i,*]
      
      if(loop_var eq 30 || loop_var eq 31) then continue
      
      total_count += total(pixel_data_copy[detect_i,*])
      
    endfor
  
  ABCD = MAKE_ARRAY(dts, /float)
  TOPBOTTOM = MAKE_ARRAY(dts, /FLO)
  
  ;prepare the maps for each detector
  for detect_i=0, dts-1 do begin ; detector loop
    ; fill in pixel counts
    
    
    ; prepare one map for first detecotr
    gmap = make_map(ulon64arr(32,32), xc = 2, yc = 0, dx = 1/8d, dy = 1/8d)
    ;set the total counts per detector to the title
    
    if ~summed then begin
    
      frame_bp[*,1] = pixel_data.counts[detect_i, 0:3]
      frame_bp[*,0] = pixel_data.counts[detect_i, 4:7]
      frame_sp[0:3] = pixel_data.counts[detect_i, 8:11]*norm_small_pixel
      
      totalcounts = total(pixel_data.counts[detect_i, *], /preserve_type)
      
      ; A + C = B + D?
      abcd[detect_i] = MAX(((frame_bp[0,*]+frame_bp[2,*])-(frame_bp[1,*]+frame_bp[3,*]))/float(total(frame_bp,1)),/ABSOLUTE) 
      TOPBOTTOM[detect_i] = (total(frame_bp[*,1])-total(frame_bp[*,0])) / float(totalcounts)
      
      ; lie, make sure there is no color gradient
      gmap.data = rebin(frame_bp, 32, 32, /sample)
      
      ; add divider to the map (spaces between each pixel)
      ;gmap.data[*,15] = 255
      
      ; assign the small pixel data to the proper location in the map
      gmap.data[0:3,14:17]= frame_sp[0]
      gmap.data[8:11,14:17]= frame_sp[1]
      gmap.data[16:19,14:17]= frame_sp[2]
      gmap.data[24:27,14:17]= frame_sp[3]
      
    endif else begin ;all pixel
      frame = pixel_data.counts[detect_i, 0:3]
      totalcounts=total(frame,/preserve_type)
      
      ; A + C = B + D?
      abcd[detect_i]=((frame[0]+frame[2])-(frame[1]+frame[3]))/float(totalcounts) 
      TOPBOTTOM[detect_i]=0
            
      ; lie, make sure there is no color gradient
      gmap.data = rebin([[transpose(frame)],[transpose(frame)]], 32, 32, /sample)
    endelse;summed pixel
    
    gmap.ID=totalcounts gt 0 ? trim(totalcounts) : ''
    
    ; replicate map for number of detectors
    if(~isvalid(gmap_all)) then gmap_all = replicate(gmap, dts) else gmap_all[detect_i] = gmap
  endfor  ; detector-loop
   
  ;scale the abcd and topbottom
  ;TOPBOTTOM /= max(abs(TOPBOTTOM))
  ;ABCD /= max(abs(ABCD))
    
  ; get indices of all but cfl and bkg
  ;det_idx_f = where(subc_str.label ne 'cfl' and subc_str.label ne 'bkg', complement=det_idx_cfl_bkg)
  
  det_idx_f = INDGEN(30)
  det_idx_cfl_bkg =[30,31]
  
  ; find the minimum and maximum pixel counts
  ; if global scale is active, do it over all energies and times, 
  ; otherwise do it only for the currently requested time and energy
  if keyword_set(dscale) && n_elements(dscale) eq 2 then begin
    mima = dscale
  end else begin
    mima = minmax(pixel_data.counts[det_idx_f, *])
  end
  
  ; enlarge the maximum range
  max_count = mima[1] + 5 
  min_count = ulong64(0)
    
  ;print, min_count, max_count
  
  ; start plotting detector pixels
  !y.omargin = [0, 9]
  !x.omargin = [1, 0]
  !x.margin = [0, 0]
  !y.margin = [1, 1]
  !p.multi = [0, 11, 3]
  
  ; plot all maps
  ; skip is used to trick IDL (see below)
  ; in the visualization, there is no detector above cfl/bkg. That
  ; "emtpy" space must be filled with a black box s. t. the other
  ; detectors do not move to the left
  skip = 0
  for di=0, dts do begin ;detector loop
    
    detect_i = di - skip
    
    ; handle the first "invisible" detector
    if(di eq 0) then begin
      skip++
      
      plot_map, make_map(make_array(10,10,VALUE=1)), drange=[0,1000], /noaxes , /notitle
      continue
    end
    
    ; specifically handle the 11th element, which is
    ; the coarse flare locator
    if di eq 11 then begin
      detect_i = 30 ;where(subc_str.label eq 'cfl')
      skip++
      
    end
    
    ; specifically handle the 22th element, which is
    ; the coarse flare locator
    if di eq 22 then begin
      detect_i = 31 ;where(subc_str.label eq 'bkg')
      skip++
      
    end
    
    ; get the detectormap
    map = gmap_all[detect_i]
    
      
    ; plot the actual detector data
    if strlen(map.id) gt 0 then begin
      plot_map, map, drange=[min_count,max_count], title=map.id, charsize=1.8, xticks=4, xticklen=1, xgridstyle=0,  yticks=1, yticklen=0 , ycharsize = 0.001, xcharsize=0.001 
    endif else begin
      ;or plot an "empty" map if there are 0 counts in the map
      plot_map, make_map(make_array(32,32,VALUE=2),xc = 2, yc = 0, dx = 1/8d, dy = 1/8d), drange=[0,100], /noaxes , /notitle
    endelse
    
    ; plot histogram for each detector 
    ;plot allways the hisogramm for CFL and BGM    
    if ~keyword_set(sinfit) or detect_i eq 30 or detect_i eq 31 then begin
      plot_x = [0,1,1,2,2,3,3,4.1]
      
      if summed then begin
        linedata = reform(pixel_data.counts[detect_i, 0:3])
        linedata = (rebin(linedata, 8, /sample) / double(max_count-min_count)) * 4. - 2.
      
        oplot, plot_x, linedata, thick=2
      endif else begin
        linedata = reform(pixel_data.counts[detect_i, 4:7])
        linedata = (rebin(linedata, 8, /sample) / double(max_count-min_count)) * 2. - 2.
        
        oplot, plot_x, linedata, thick=2
        
        linedata = reform(pixel_data.counts[detect_i, 0:3])
        linedata = (rebin(linedata, 8, /sample) / double(max_count-min_count)) * 2.
      
        oplot, plot_x, linedata, thick=2
      end
       
    endif else begin
      ; plot sinefit for each detector
      n_plot_points = 20.d
      
      ; the x range for fiting is a full period
      x = 2.d*!pi * findgen(n_plot_points) / (n_plot_points-1)
      
      plot_x = 3.95 * findgen(n_plot_points) / (n_plot_points-1)
      if summed then begin
        linedata = reform(pixel_data.counts[detect_i, 0:3]) / double(max_count-min_count)
        y = stx_sine(x, linedata)
        ; shift (-2.d) to the upper part of the chart and scale it to the plot
        plot_y = (y * 4.) - 2.
        
        oplot, plot_x, plot_y , thick=2
        oplot, plot_x, replicate(mean(plot_y), n_plot_points)
      end else begin
        
        linedata = reform(pixel_data.counts[detect_i, 4:7]) / double(max_count-min_count)
        y = stx_sine(x, linedata)
        ; shift (-2.d) to the upper part of the chart and scale it to the plot
        plot_y = (y * 2.) - 2.
        
        oplot, plot_x, plot_y , thick=2
        oplot, plot_x, replicate(mean(plot_y), n_plot_points)
        
        linedata = reform(pixel_data.counts[detect_i, 0:3]) / double(max_count - min_count)
        y = stx_sine(x, linedata)
        ; scale it to the plot
        plot_y = y * 2.
        
        oplot, plot_x, plot_y , thick=2
        oplot, plot_x, replicate(mean(plot_y) ,n_plot_points)
        
      endelse; all fixel
      
    endelse; sinfit
    
    if KEYWORD_SET(showabcdratio) then begin
      ;plot, [1], [1], XStyle=1, YStyle=1, TICKLEN=0, /NoData, yrange=[-2,2], xrange=[0,4], title="sss",charsize=1.8, XTICKFORMAT="(A1)", YTICKFORMAT="(A1)"
      ;Axis, /XAxis, 0, TICKLEN=0, XTICKFORMAT="(A1)"
      ;Axis, /YAxis, 2, TICKLEN=0, YTICKFORMAT="(A1)"
      oplot, [2,2-abcd[detect_i]*2],[0,topbottom[detect_i]*2],thick=6 , color = 250
      oplot, [2,2-abcd[detect_i]*2],[0,topbottom[detect_i]*2],thick=3 , color = 20
    end
    
  endfor ;detector loop
  
 
  ;draw the color bar on the top of the chart
  message, 'REMOVED COLORBAR FROM UTIL, MAY NOT BE NEEDED ANYMORE IN IDL 8.2+', /continue
  colorbar, min=min_count, max=max_count, charsize=3, position=[0.25, 0.92, 0.95, 0.96], format='(I)'
  
  
  xyouts, 0.01, 0.97, pixel_data[0].type, /normal, charsize=1.2, charthick=1
  xyouts, 0.01, 0.92, "TotCount: "+trim(total_count), /normal, charsize=1.2, charthick=1
  xyouts, 0.01, 0.82, "Time: "+stx_time2any(pixel_data[0].time_range[0],/ECS)+" Duration: "+trim(stx_time_diff(pixel_data[0].time_range[1],pixel_data[0].time_range[0]))+"sec", /normal, charsize=1.2, charthick=1  
  xyouts, 0.01, 0.87, "Energy: "+trim(pixel_data[0].energy_range[0])+"-"+trim(pixel_data[0].energy_range[1])+"keV", /normal, charsize=1.2, charthick=1
  xyouts, 0.01, 0.57, "CFL / BKG", /normal, charsize=1.2, charthick=1
  cleanplot, /silent  
end
