;+
; :file_comments:
;   The energy calibration plot object. It can be used to plot STIX energy calibration spectra.
;   Therefore STIX energy calibration spectrum objects are consumed and a plot is created out
;   of the data.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    11-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
;    11-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_energy_calibration_spectrum_plot::init
  ; Initialize the base object
  base_initialization = self->stx_line_plot::init()
  
  ; Initialize the pointer for the data array
  self.data_array_ptr = ptr_new()
  
  return, base_initialization
end

pro stx_energy_calibration_spectrum_plot::cleanup
  if self.data_array_ptr ne !null then ptr_free, self.data_array_ptr
  if self.plot_array ne !NULL then begin
    plot_pointers = *self.plot_array
    for i=0,size(plot_pointers, /n_elements)-1 do begin
      if plot_pointers[i] ne !NULL then ptr_free, plot_pointers[i]
    endfor
    ptr_free, self.plot_array
  endif
end

;+
; :description:
;    Plots the data of a stx energy calibration spectrum object.
;
; :Params:
;
; :returns:
;
; :history:
;    11-Jun-2015 - Roman Boutellier (FHNW), Initial release
;    23-Jan-2017 – ECMD (Graz), Now using x-axis title found in stx_line_plot_styles as default for all plots.
;-
pro stx_energy_calibration_spectrum_plot::plot, energy_calibration_spectrum_object, subspectra_to_plot=subspectra_to_plot, $
                                                pixel_mask=pixel_mask, detector_mask=detector_mask, overplot=overplot, $
                                                dimensions=dimensions, position=position, current=current, $
                                                add_legend=add_legend, recalculate_data=recalculate_data, _extra=extra
  
  ; Get the default styling
  default_styles = self->_get_styles()
  
  ; Set the default styles
  default, position, default_styles.position
  default, dimensions, default_styles.dimensions
  default, styles, default_styles.colors
  default, names, default_styles.names
  default, xtitle, default_styles.x_title
  default, ytitle, default_styles.y_title
  default, subspectra_to_plot, indgen(n_elements(energy_calibration_spectrum_object.SUBSPECTRA)) 
  
 
  
  ; Check if the data has already been calculated and if the user requested a recalculation of the data
  if ((self.data_array_ptr eq !NULL) or (keyword_set(recalculate_data))) then begin   ;or (size(*self.data_array_ptr, /n_elements) lt 1)
    ; Extract the data. There is a number (at most 8) of subspectra which are each plotted in the same window.
    subspectra = energy_calibration_spectrum_object.subspectra
    
    ; Plot the subspectra which are requested in one window. The keyword subspectra_to_plot contains an array with the indices of
    ; the spectra which should be plotted
    
    n_spectra_to_plot = n_elements(subspectra_to_plot)
    
    result_array = dblarr(n_spectra_to_plot,1024)
    names = "subSpec: "+trim(indgen(n_spectra_to_plot))
    for ind=0,n_spectra_to_plot-1 do begin
      
      ; Get the current subspectrum
      current_subspectrum = subspectra[subspectra_to_plot[ind]].spectrum
      pixel_mask = make_array(12, /byte, value=1b);  subspectra[subspectra_to_plot[ind]].pixel_mask
      detector_mask = make_array(32, /byte, value=1b) ; subspectra[subspectra_to_plot[ind]].detector_mask
      
      e_start = subspectra[subspectra_to_plot[ind]].LOWER_ENERGY_BOUND_CHANNEL
      e_range = subspectra[subspectra_to_plot[ind]].NUMBER_OF_SUMMED_CHANNELS
      e_n = subspectra[subspectra_to_plot[ind]].NUMBER_OF_SPECTRAL_POINTS
      
      for e=0, e_n-1 do begin
        e_bins = indgen(e_range)+e_start+(e*e_range)
        for p=0, size(pixel_mask, /n_elements)-1 do begin
          current_pixel_mask_entry = pixel_mask[p]
          if current_pixel_mask_entry eq 1 then begin
            for d=0, size(detector_mask, /n_elements)-1 do begin
              current_detector_mask_entry = detector_mask[d]
              if current_detector_mask_entry eq 1 then begin
                result_array[ind,e_bins] += current_subspectrum[e,p,d] / (1.0d* e_range)
              endif
            endfor
          endif
        endfor
      endfor

    endfor
    
    ; Store the array
    self.data_array_ptr = ptr_new(result_array)
  endif else begin
    ; TODO Load the correct values from the stored array
    result_array = intarr(size(subspectra_to_plot,/n_elements), 1024)
    for ind=0, size(subspectra_to_plot, /n_elements)-1 do begin
      result_array[ind, *] = (*self.data_array_ptr)[subspectra_to_plot[ind], *]
    endfor
  endelse
  ; TODO Prepare the x-axis
  x_sub_axis = indgen(1024)
  x_axis = intarr(size(subspectra_to_plot,/n_elements),1024)
  for i=0, size(subspectra_to_plot,/n_elements)-1 do begin
    x_axis[i,*] = x_sub_axis
  endfor
  
  x_axis=reform(x_axis)
  result_array = reform(result_array)
  
  ; Plot the spectra
  if keyword_set(add_legend) then begin
    ;position = position.nmbr_subplot1
    void = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position, current=current, styles=styles, $
                                        names=names, ylog=0, xtitle = xtitle, ytitle = ytitle, /add_legend, _extra=extra)
  endif else begin
    void = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position, current=current, styles=styles, $
                                        names=names, ylog=0,  xtitle = xtitle, ytitle = ytitle, _extra=extra)
  endelse
end

;+
; :description:
;    Plots the data of a stx energy calibration spectrum object.
;
; :Params:
;
; :returns:
;
; :history:
;    11-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectrum_plot::plot2, energy_calibration_spectrum_object, subspectra_to_plot=subspectra_to_plot, $
                                                pixel_mask=pixel_mask, detector_mask=detector_mask, overplot=overplot, $
                                                dimensions=dimensions, position=position, current=current, $
                                                add_legend=add_legend, recalculate_data=recalculate_data, out_compacted_spectra = out_compacted_spectra, _extra=extra
  
  ; Get the default styling
  default_styles =  stx_line_plot_styles(/energy_calibration_pixel)
  
  ; Set the default styles
  default, position, default_styles.position
  default, dimensions, default_styles.dimensions
  default, styles, default_styles.colors
  default, names, default_styles.names
  default, x_title, default_styles.x_title
  default, y_title, default_styles.y_title
  default, subspectra_to_plot, indgen(n_elements(energy_calibration_spectrum_object.SUBSPECTRA))
  
   
  ; Extract the data. There is a number (at most 8) of subspectra which are each plotted in the same window.
  subspectra = energy_calibration_spectrum_object.subspectra
 
  nmbr_pixels = 12
  result_array = make_array(nmbr_pixels, 1024, /double, value=!VALUES.d_nan )
  

  for ind=0, size(subspectra_to_plot, /n_elements)-1 do begin
  ;for ind=2, 2 do begin
    ; Get the current subspectrum
    current_subspectrum = subspectra[subspectra_to_plot[ind]].spectrum
    
    pixel_mask = make_array(12, /byte, value=1b);  subspectra[subspectra_to_plot[ind]].pixel_mask
    detector_mask = make_array(32, /byte, value=1b) ; subspectra[subspectra_to_plot[ind]].detector_mask

    e_start = subspectra[subspectra_to_plot[ind]].lower_energy_bound_channel
    e_range = subspectra[subspectra_to_plot[ind]].number_of_summed_channels
    e_n = subspectra[subspectra_to_plot[ind]].number_of_spectral_points
     
    
    for e=0, e_n-1 do begin
      e_bins = indgen(e_range)+e_start+(e*e_range)
 
      for p=0, nmbr_pixels-1 do begin
        current_pixel_mask_entry = pixel_mask[p]
        if current_pixel_mask_entry eq 1 then begin
          for d=0, size(detector_mask, /n_elements)-1 do begin
            current_detector_mask_entry = detector_mask[d]
            if current_detector_mask_entry eq 1 then begin
              nan_idx = where(finite(result_array[p, e_bins],/nan),nan_count)
              if (nan_count gt 0) then result_array[p, e_bins[nan_idx]] = 0
              result_array[p,e_bins] += current_subspectrum[e,p,d]
            endif
          endfor
        endif
      endfor
    endfor
  endfor
  
  out_compacted_spectra = result_array 
  
  ; TODO Prepare the x-axis
  x_sub_axis = indgen(1024)
  x_axis = intarr(nmbr_pixels,1024)
  for i=0, nmbr_pixels-1 do x_axis[i,*] = x_sub_axis
  
  
 
 
  sub_n = n_elements(subspectra_to_plot)
  
  spectra = dblarr(sub_n, 1024)
  spectra[*] = !VALUES.d_nan
  spectranames = strarr(sub_n)
  for ind=0, size(subspectra_to_plot, /n_elements)-1 do begin
    ; Get the current subspectrum
    current_subspectrum = subspectra[subspectra_to_plot[ind]].spectrum

    pixel_mask = make_array(12, /byte, value=1b);  subspectra[subspectra_to_plot[ind]].pixel_mask
    detector_mask = make_array(32, /byte, value=1b) ; subspectra[subspectra_to_plot[ind]].detector_mask

    e_start = subspectra[subspectra_to_plot[ind]].lower_energy_bound_channel
    e_range = subspectra[subspectra_to_plot[ind]].number_of_summed_channels
    e_n = subspectra[subspectra_to_plot[ind]].number_of_spectral_points
    
    eband = indgen(e_range) + e_start
    for e=0, e_n-1 do begin
      spectra[ind,eband] = ind + 1 + (0.2 * (e mod 2))
      eband+=e_range
    endfor
    

    spectranames[ind] = "SubSpectra "+trim(ind+1)+": ["+trim(e_start)+", "+trim(e_range)+", "+trim(e_n)+"]"
  endfor
  
  
  sum_plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position, current=current, styles=styles, $
     names=names, add_legend = keyword_set(add_legend), ylog=0, _extra=extra, xtitle="", ytitle=y_title)
  
  sp_plot = self->_plot(reform(x_axis[0:sub_n-1,*]), reform(spectra), current=self->getwindow(), position=[0.1,0.1,0.65,0.3], styles=styles,  $
                                        names=spectranames, ylog=0, ytitle="Subspectra #", xtitle=x_title)

 
end



;+
; :description:
;    Plots the data of a stx energy calibration spectrum object.
;
; :Params:
;
; :returns:
;
; :history:
;    11-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectrum_plot::plot3, energy_calibration_spectrum_object, subspectra_to_plot=subspectra_to_plot, $
                                                pixel_mask=pixel_mask, detector_mask=detector_mask, overplot=overplot, $
                                                dimensions=dimensions, current=current, $
                                                add_legend=add_legend, recalculate_data=recalculate_data, _extra=extra
  
  ; Get the default styling
  default_styles = self->_get_styles()
  
  ; Set the default styles
  default, dimensions, default_styles.dimensions
  default, styles, default_styles.colors
  default, names, default_styles.names
  default, title, ""
  default, xtitle, ""
  default, ytitle, ""
  xmajor = -1
  ymajor = -1
  font_size = 12
  
  ; Set the text for every subspectrum
  subspectra_text_array = ['Subspectrum 0', 'Subspectrum 1', 'Subspectrum 2', 'Subspectrum 3', 'Subspectrum 4', 'Subspectrum 5', 'Subspectrum 6', 'Subspectrum 7']
  
  ; Get the number of subspectra which will be plotted
  number_subspectra_to_plot = size(subspectra_to_plot, /n_elements)
  ; Prepare the layout parameter depending on the number of subspectra to plot
  position_struct = default_styles.position
  if(number_subspectra_to_plot eq 1) then begin
    position_array = position_struct.nmbr_subplot1
  endif
  if(number_subspectra_to_plot eq 2) then begin
    position_array = position_struct.nmbr_subplot2
    title = ''
    xtitle = ''
    ytitle = ''
  endif
  if(number_subspectra_to_plot eq 3) then begin
    position_array = position_struct.nmbr_subplot3
    title = ''
    xtitle = ''
    ytitle = ''
    ymajor = 5
  endif
  if(number_subspectra_to_plot eq 4) then begin
    position_array = position_struct.nmbr_subplot4
    title = ''
    xtitle = ''
    ytitle = ''
    ymajor = 5
  endif
  if(number_subspectra_to_plot eq 5) then begin
    position_array = position_struct.nmbr_subplot5
    title = ''
    xtitle = ''
    ytitle = ''
    xmajor = 3
    ymajor = 5
    font_size = 11
  endif
  if(number_subspectra_to_plot eq 6) then begin
    position_array = position_struct.nmbr_subplot6
    title = ''
    xtitle = ''
    ytitle = ''
    xmajor = 3
    ymajor = 5
    font_size = 11
  endif
  if(number_subspectra_to_plot eq 7) then begin
    position_array = position_struct.nmbr_subplot7
    title = ''
    xtitle = ''
    ytitle = ''
    xmajor = 3
    ymajor = 5
    font_size = 10
  endif
  if(number_subspectra_to_plot eq 8) then begin
    position_array = position_struct.nmbr_subplot8
    title = ''
    xtitle = ''
    ytitle = ''
    xmajor = 3
    ymajor = 5
    font_size = 10
  endif
  
  
  ; Extract the data. There is a number (at most 8) of subspectra which are each plotted in the same window.
  subspectra = energy_calibration_spectrum_object.subspectra
  ; Extract the number of data entries per pixel and detector (normally 1024)
  nmbr_data_entries = (size(subspectra[0].spectrum))[1]
  
  ; Plot the subspectra which are requested in one window. The keyword subspectra_to_plot contains an array with the indices of
  ; the spectra which should be plotted
  void = where(pixel_mask eq 1, nmbr_pixels)
  ; Prepare the array which holds the plot objects
  self.plot_array = ptr_new(ptrarr(number_subspectra_to_plot))
  if n_elements(current) gt 0 then current.refresh, /disable
  for ind=0, number_subspectra_to_plot-1 do begin
    ; For every subspectrum create the up to 12 data arrays (for all needed pixels) and plot them
    result_array = lonarr(nmbr_data_entries, nmbr_pixels)
    ; Get the current subspectrum
    current_subspectrum = subspectra[subspectra_to_plot[ind]].spectrum
    
    ; Index in the result array for the second dimension
    pixel_result_array_index = 0
    ; Add up the entries of all detectors for the needed pixels
    ; First loop over all pixels
    for p=0, size(pixel_mask, /n_elements)-1 do begin
      current_pixel_mask_entry = pixel_mask[p]
      if current_pixel_mask_entry eq 1 then begin
        ; The current pixel is set to 1 in the mask and therefore will appear in the result
        ; Now go over every detector and add the according arrays of entries up
        for d=0, size(detector_mask, /n_elements)-1 do begin
          current_detector_mask_entry = detector_mask[d]
          if current_detector_mask_entry eq 1 then begin
            ; The current detector is set to 1 in the mask and therefore will appear in the result
            result_array[*,pixel_result_array_index] += current_subspectrum[*,p,d]
          endif
        endfor
        pixel_result_array_index++
      endif
    endfor
    
    ; Transpose the result array
    result_array = transpose(result_array)
    
    ; TODO Prepare the x-axis
    x_sub_axis = indgen(nmbr_data_entries)
;    x_axis_step_size = (energy_calibration_spectrum_object.end_time.value.mjd - energy_calibration_spectrum_object.start_time.value.mjd) / 1024
;    x_axis_start_value = energy_calibration_spectrum_object.start_time.value.mjd
;    for i=0, 1023 do begin
;      x_sub_axis[i] = x_axis_start_value + i*x_axis_step_size
;    endfor
    x_axis = intarr(nmbr_pixels,nmbr_data_entries)
    for i=0, nmbr_pixels-1 do begin
      x_axis[i,*] = x_sub_axis
    endfor
    
    ; Complete the layout parameter
;    complete_layout = [layout_param,ind+1]

    ; Get the current text to add
    current_additional_text = subspectra_text_array[subspectra_to_plot[ind]]
    
    if ind eq 0 then begin
      ; The first plot
      if keyword_set(add_legend) then begin
        if number_subspectra_to_plot eq 1 then begin
          plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position_array, current=current, styles=styles, xmajor=xmajor, ymajor=ymajor, $
                                              names=names, title=title, xtitle=xtitle, ylog=0, ytitle=ytitle, font_size=font_size, /add_legend, additional_text=current_additional_text, _extra=extra);, layout=complete_layout
        endif else begin
          plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position_array[*,ind], current=current, styles=styles, xmajor=xmajor, ymajor=ymajor, $
                                              names=names, title=title, xtitle=xtitle, ylog=0, ytitle=ytitle, font_size=font_size, /add_legend, additional_text=current_additional_text, _extra=extra);, layout=complete_layout
        endelse
      endif else begin
        if number_subspectra_to_plot eq 1 then begin
          plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position_array, current=current, styles=styles, xmajor=xmajor, ymajor=ymajor, $
                                              names=names, title=title, xtitle=xtitle, ylog=0, ytitle=ytitle, font_size=font_size, additional_text=current_additional_text, _extra=extra);, layout=complete_layout
        endif else begin
          plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position_array[*,ind], current=current, styles=styles, xmajor=xmajor, ymajor=ymajor, $
                                              names=names, title=title, xtitle=xtitle, ylog=0, ytitle=ytitle, font_size=font_size, additional_text=current_additional_text, _extra=extra);, layout=complete_layout
        endelse
      endelse
      if number_subspectra_to_plot gt 1 then begin
        ; Add the axis texts to the left of the lefternmost plot and below the lowest plot in case there are more than 1 plots
        t = text(0.02,0.4,'Entries per ADC bin',orientation=90)
        t2 = text(0.4,0.01,'ADC value')
      endif
    endif else begin
      ; Overplots
      if number_subspectra_to_plot eq 1 then begin
        plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position_array, current=current, styles=styles, xmajor=xmajor, ymajor=ymajor, $
                                            names=names, title=title, xtitle=xtitle, ylog=0, ytitle=ytitle, layout=complete_layout, font_size=font_size, additional_text=current_additional_text, _extra=extra);, layout=complete_layout, /overplot
      endif else begin
        plot = self->stx_line_plot::_plot(x_axis, result_array, dimensions=dimensions, position=position_array[*,ind], current=current, styles=styles, xmajor=xmajor, ymajor=ymajor, $
                                            names=names, title=title, xtitle=xtitle, ylog=0, ytitle=ytitle, font_size=font_size, additional_text=current_additional_text, _extra=extra);, layout=complete_layout, /overplot
      endelse
    endelse
    (*self.plot_array)[ind] = plot
  endfor
  if n_elements(current) gt 0 then current.refresh
end

pro stx_energy_calibration_spectrum_plot::plot_legend, legend_window_id
  plot = self->stx_line_plot::_plot_legend(window_id=legend_window_id)
end
  

pro stx_energy_calibration_spectrum_plot::plot_direct_graphics, energy_calibration_spectrum_object, subspectra_to_plot=subspectra_to_plot, $
                                                pixel_mask=pixel_mask, detector_mask=detector_mask, overplot=overplot, $
                                                dimensions=dimensions, current=current, $
                                                add_legend=add_legend, recalculate_data=recalculate_data, _extra=extra
                                                
end

;+
; :description:
; 	 Get the default styles for the energy calibration spectra.
;
; :returns:
;
; :history:
; 	 15-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_energy_calibration_spectrum_plot::_get_styles
  ; Get the default styles
  default_styles = stx_line_plot_styles(/energy_calibration_pixel)
  return, default_styles
end

function stx_energy_calibration_spectrum_plot::get_plot_array
  return, self.plot_array
end

pro stx_energy_calibration_spectrum_plot__define
  compile_opt idl2
  
  define = {stx_energy_calibration_spectrum_plot, $
    data_array_ptr: ptr_new(), $
    plot_array: ptr_new(), $
    inherits stx_line_plot $
  }
end