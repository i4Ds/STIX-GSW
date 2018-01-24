;+
; :file_comments:
;    this is the gui for the HK data
;
; :categories:
;    HK data, software, gui
;
; :examples:
;
; :history:
;    10-Feb-2014 - Marek Steslicki (Wro), Initial release
;-

;+
; :description:
;      This function initializes the object. It is called automatically upon creation of the object.
;
; :Params:
;
; :returns:
;
; :examples:
;    a=obj_new('stx_HK_plotter')
;    a->plot,'16:30 22-May-2001','16:33 22-May-2001',/motor_motions,/detectors_temp_q1
;
; :history:
;      25-Feb-2015 - Marek Steslicki (Wro), Initial release
;-
function stx_HK_plotter_test::init, fsw, plot=plot, _extra=extra
  return, self->stx_plotter::init(plot=plot, _extra = extra)
end

pro stx_HK_plotter_test::cleanup
  ; Call our superclass Cleanup method
  self->stx_plotter::Cleanup
end


function stx_HK_plotter_test::_axis_title, type=type
  case type of
    'instrument_mode': return, 'instrument mode'
    'PSU_temp' : return, 'PSU temperature'
    'IDPU_temp_1': return, 'IDPU temperature 1'
    'IDPU_temp_2': return, 'IDPU temperature 2'
    'current_33': return, 'Essential digital 3.3V current'
    'current_25': return, 'Essential digital 2.5V current'
    'current_15': return, 'Essential digital 1.5V current'
    'aspect_temp_01': return, 'Aspect temperature 1'
    'aspect_temp_02': return, 'Aspect temperature 2'
    'aspect_temp_03': return, 'Aspect temperature 3'
    'aspect_temp_04': return, 'Aspect temperature 4'
    'aspect_temp_05': return, 'Aspect temperature 5'
    'aspect_temp_06': return, 'Aspect temperature 6'
    'aspect_temp_07': return, 'Aspect temperature 7'
    'aspect_temp_08': return, 'Aspect temperature 8'
    'aspect_temp_09': return, 'Aspect temperature 9'
    'aspect_temp_10': return, 'Aspect temperature 10'
    'attenuator_voltage': return, 'Attenuator voltage'
    'HV_PSU_voltage_1': return, 'HV PSU voltage 1'
    'HV_PSU_voltage_2': return, 'HV PSU voltage 2'
    'detectors_temp_q1': return, 'Detectors temperature quarter 1'
    'detectors_temp_q2': return, 'Detectors temperature quarter 2'
    'detectors_temp_q3': return, 'Detectors temperature quarter 3'
    'detectors_temp_q4': return, 'Detectors temperature quarter 4'
    'detectors_current_q1': return, 'Detectors current quarter 1'
    'detectors_current_q2': return, 'Detectors current quarter 2'
    'detectors_current_q3': return, 'Detectors current quarter 3'
    'detectors_current_q4': return, 'Detectors current quarter 4'
    'active_IDPU': return, 'IDPU Nominal or Redundant'
    'med_lt_accumulators': return, 'Median value of live time accumulators, average since last HK packed'
    'max_lt_accumulators': return, 'Maximum value of live time accumulators, average since last HK packed'
    'HV_regulators': return, 'HV regulators on/off'
    'attenuator_currents': return, 'Summed attenuator currents'
    'motor_motions': return, 'Total motions of attenuator motor'
    'flagged_detectors': return, 'Currently flagged detectors' 
    'xlabel': return, 'Time (UTC)'
    else: return, ''
  endcase
end

function stx_HK_plotter_test::_number2month, month
  case month of
    1: return, 'January'
    2: return, 'February'
    3: return, 'March'
    4: return, 'April'
    5: return, 'May'
    6: return, 'June'
    7: return, 'July'
    8: return, 'August'
    9: return, 'September'
    10: return, 'October'
    11: return, 'November'
    12: return, 'December'
    else: return, ''
  endcase
end

pro stx_HK_plotter_test::plot, t_start, t_end, $; commented keywords are not implemented
;  rcr=rcr, $ ; 
;  RCR_no_numbers=RCR_no_numbers, $ ;
;  instrument_mode=instrument_mode, $; instrument mode
  PSU_temp=PSU_temp, $ ;PSU temperature
  IDPU_temp_1=IDPU_temp_1, $ ;IDPU temperature 1
  IDPU_temp_2=IDPU_temp_2, $ ;IDPU temperature 2
  current_33=current_33, $ ;Essential digital 3.3V current
  current_25=current_25, $ ;Essential digital 2.5V current
  current_15=current_15, $ ;Essential digital 1.5V current
  aspect_temp_01=aspect_temp_01, $ ;Aspect temperature 1
  aspect_temp_02=aspect_temp_02, $ ;Aspect temperature 2
  aspect_temp_03=aspect_temp_03, $ ;Aspect temperature 3
  aspect_temp_04=aspect_temp_04, $ ;Aspect temperature 4
  aspect_temp_05=aspect_temp_05, $ ;Aspect temperature 5
  aspect_temp_06=aspect_temp_06, $ ;Aspect temperature 6
  aspect_temp_07=aspect_temp_07, $ ;Aspect temperature 7
  aspect_temp_08=aspect_temp_08, $ ;Aspect temperature 8
  aspect_temp_09=aspect_temp_09, $ ;Aspect temperature 9
  aspect_temp_10=aspect_temp_10, $ ;Aspect temperature 10
  attenuator_voltage=attenuator_voltage, $ ;Attenuator voltage
  HV_PSU_voltage_1=HV_PSU_voltage_1, $ ;HV PSU voltage 1
  HV_PSU_voltage_2=HV_PSU_voltage_2, $ ;HV PSU voltage 2
  detectors_temp_q1=detectors_temp_q1, $ ;Detectors temperature quarter 1
  detectors_temp_q2=detectors_temp_q2, $ ;Detectors temperature quarter 2
  detectors_temp_q3=detectors_temp_q3, $ ;Detectors temperature quarter 3
  detectors_temp_q4=detectors_temp_q4, $ ;Detectors temperature quarter 4
  detectors_current_q1=detectors_current_q1, $ ;Detectors current quarter 1
  detectors_current_q2=detectors_current_q2, $ ;Detectors current quarter 2
  detectors_current_q3=detectors_current_q3, $ ;Detectors current quarter 3
  detectors_current_q4=detectors_current_q4, $ ;Detectors current quarter 4
;  active_IDPU=active_IDPU, $ ;IDPU Nominal or Redundant
;  med_lt_accumulators=med_lt_accumulators, $ ;Median value of live time accumulators, average since last HK packed
;  max_lt_accumulators=max_lt_accumulators, $ ;Maximum value of live time accumulators, average since last HK packed
;  HV_regulators=HV_regulators, $ ;HV regulators on/off
  attenuator_currents=attenuator_currents, $ ;Summed attenuator currents
  motor_motions=motor_motions, $  ;Total motions of attenuator motor
;  flagged_detectors=flagged_detectors;Currently flagged detectors
    _extra=extra

  ;  when t_start given as a string transformation to JD
  if size(t_start,/type) eq 7 then begin
    start_mjd = anytim(t_start,/mjd)
    start_jd = 1.d*start_mjd.mjd + start_mjd.time/86400000.d + 2400000.5d
  endif else begin
    start_jd=1.d*t_start
  endelse
  
  ; when t_end given as a string transformation to JD
  if size(t_end,/type) eq 7 then begin
    end_mjd = anytim(t_end,/mjd)
    end_jd = 1.d*end_mjd.mjd + end_mjd.time/86400000.d + 2400000.5d
  endif else begin
    end_jd=1.d*t_end
  endelse
  
  self.JD_range=[ start_jd, end_jd ]
  
  self.plot_types=list()
  
  if keyword_set(PSU_temp) then self.plot_types.add, 'PSU_temp'
  if keyword_set(IDPU_temp_1) then self.plot_types.add, 'IDPU_temp_1'
  if keyword_set(IDPU_temp_2) then self.plot_types.add, 'IDPU_temp_2'
  if keyword_set(current_33) then self.plot_types.add, 'current_33'
  if keyword_set(current_25) then self.plot_types.add, 'current_25'
  if keyword_set(current_15) then self.plot_types.add, 'current_15'
  if keyword_set(aspect_temp_01) then self.plot_types.add, 'aspect_temp_01'
  if keyword_set(aspect_temp_02) then self.plot_types.add, 'aspect_temp_02'
  if keyword_set(aspect_temp_03) then self.plot_types.add, 'aspect_temp_03'
  if keyword_set(aspect_temp_04) then self.plot_types.add, 'aspect_temp_04'
  if keyword_set(aspect_temp_05) then self.plot_types.add, 'aspect_temp_05'
  if keyword_set(aspect_temp_06) then self.plot_types.add, 'aspect_temp_06'
  if keyword_set(aspect_temp_07) then self.plot_types.add, 'aspect_temp_07'
  if keyword_set(aspect_temp_08) then self.plot_types.add, 'aspect_temp_08'
  if keyword_set(aspect_temp_09) then self.plot_types.add, 'aspect_temp_09'
  if keyword_set(aspect_temp_10) then self.plot_types.add, 'aspect_temp_10'
  if keyword_set(attenuator_voltage) then self.plot_types.add, 'attenuator_voltage'
  if keyword_set(HV_PSU_voltage_1) then self.plot_types.add, 'HV_PSU_voltage_1'
  if keyword_set(HV_PSU_voltage_2) then self.plot_types.add, 'HV_PSU_voltage_2'
  if keyword_set(detectors_temp_q1) then self.plot_types.add, 'detectors_temp_q1'
  if keyword_set(detectors_temp_q2) then self.plot_types.add, 'detectors_temp_q2'
  if keyword_set(detectors_temp_q3) then self.plot_types.add, 'detectors_temp_q3'
  if keyword_set(detectors_temp_q4) then self.plot_types.add, 'detectors_temp_q4'
  if keyword_set(detectors_current_q1) then self.plot_types.add, 'detectors_current_q1'
  if keyword_set(detectors_current_q2) then self.plot_types.add, 'detectors_current_q2'
  if keyword_set(detectors_current_q3) then self.plot_types.add, 'detectors_current_q3'
  if keyword_set(detectors_current_q4) then self.plot_types.add, 'detectors_current_q4'
  if keyword_set(attenuator_currents) then self.plot_types.add, 'attenuator_currents'
  if keyword_set(motor_motions) then self.plot_types.add, 'motor_motions'

  n=n_elements(self.plot_types)

  if n gt 0 then begin
    if n gt 2 then begin
      message, 'only two plots accepted' ,/inf 
    endif
    self->stx_plotter::create_plot, function_name='_create_plot_HK', key='windows_HK', _extra=extra
    self->_update_plot_HK 
  endif else if not keyword_set(rcr) then message, 'nothing to plot', /inf 

;  if show_rcr then begin (not implemented, yet)
  if keyword_set(rcr) then begin
;    self->stx_plotter::create_plot, function_name='_create_plot_RCR', key='windows_RCR', _extra=extra
;    self->_update_plot_RCR
  endif

end


function stx_HK_plotter_test::_create_plot_HK, current=current, showxlabels=showxlabels, position=position, _extra=extra
  COMPILE_OPT IDL2, HIDDEN

  default, position, [0.1,0.1,0.9,0.9]
  default, showxlabels, 1

  n=n_elements(self.plot_types)
  data1=stx_hk_read_test_data(self.JD_range[0], self.JD_range[1], time=jd_data1, data=(list(self.plot_types,/extract))[0])

  plot1_color='navy'
  plot2_color='green'
  
  h1_plot=plot(jd_data1,data1, $
               current=current, $
               axis_style=1, $
               position=position, $
               xtickformat = 'LABEL_DATE', $
               xtickfont_size = 8, $
               ytickfont_size = 10, $
               ygridstyle=0, $
               ytext_color=plot1_color, $
               color=plot1_color, $
               xrange=[self.JD_range[0], self.JD_range[1]], $
               xtitle=xlabel, $
               ytitle=self->_axis_title(type=(list(self.plot_types,/extract))[0]), $
               /OVERPLOT ) 

  (self.plots)["HK"] = [ h1_plot ]

  if n gt 1 then begin
    data2=stx_hk_read_test_data(self.JD_range[0], self.JD_range[1], time=jd_data2, data=(list(self.plot_types,/extract))[1])
    h2_plot=plot(jd_data2,data2, $
                 AXIS_STYLE=0, $
                 position=position, $
                 xrange=h1_plot.xrange, $
                 ytext_color=plot2_color, $
                 color=plot2_color, $
                 /CURRENT)

    
    a2 = axis('y', $
                 target=h2_plot, $
                 location=[(h1_plot.xrange)[1],0,0], $     ; right axis, data coordinates
                 textpos=1, $                           ; text face 
                 tickdir=1, $                           ; ticks face 
                 text_color=plot2_color, $
                 title=self->_axis_title(type=(list(self.plot_types,/extract))[1]), $
                 tickfont_size = 10, $
                 major=5, $                            
                 minor=3 )

               (self.plots)["HK"] = [ h1_plot, h2_plot, a2 ]

  endif

  HK_plot->Refresh, /DISABLE
  self->_registermouseevents, hk_plot.window
  hk_plot->Refresh, /DISABLE
  return, h1_plot.window
end

;function stx_HK_plotter_test::_create_plot_RCR, current=current, showxlabels=showxlabels, position=position, _extra=extra
;  COMPILE_OPT IDL2, HIDDEN
;  self->_registermouseevents, rcr_plot.window
;  (self.plots)["RCR"] = rcr_plot
;  rcr_plot->Refresh, /DISABLE
;  return, rcr_plot.window
;end



pro stx_HK_plotter_test::_update_plot_HK
  COMPILE_OPT IDL2, HIDDEN

  n_plots=n_elements((self.plots)["HK"])
  self.JD_range=((self.plots)["HK"])[0].xrange

  n=n_elements(self.plot_types)
  data1=stx_hk_read_test_data(self.JD_range[0], self.JD_range[1], time=jd_data1, data=(list(self.plot_types,/extract))[0])
  if n gt 1 then  data2=stx_hk_read_test_data(self.JD_range[0], self.JD_range[1], time=jd_data2, data=(list(self.plot_types,/extract))[1])

  data_lenght=self.JD_range[1]-self.JD_range[0]
  label_date_format = LABEL_DATE( DATE_FORMAT='%M, %Y' )
  caldat, self.JD_range[0], Month, Day, Year, Hour, Minute, Second
  if data_lenght lt 180 then begin 
      label_date_format = LABEL_DATE( DATE_FORMAT='%M %D, %Y' )
      ((self.plots)["HK"])[0].xtitle='Universal Time'
  endif
  if data_lenght lt 30 then begin 
      label_date_format = LABEL_DATE( DATE_FORMAT='%M %D' )
      ((self.plots)["HK"])[0].xtitle='Universal Time ('+trim(string(Year))+')'
  endif
  if data_lenght lt 5 then begin 
      label_date_format = LABEL_DATE( DATE_FORMAT='%M %D %H:%I' )
      ((self.plots)["HK"])[0].xtitle='Universal Time ('+trim(string(Year))+')'
  endif
  if data_lenght lt 2 then begin 
      label_date_format = LABEL_DATE( DATE_FORMAT='%H:%I' )
      ((self.plots)["HK"])[0].xtitle='Universal Time ('+trim(self->_number2month(Month))+' '+trim(string(Day))+', '+trim(string(Year))+')'
  endif
  if data_lenght lt 0.1 then begin 
      label_date_format = LABEL_DATE( DATE_FORMAT='%H:%I:%S' )
      ((self.plots)["HK"])[0].xtitle='Universal Time ('+trim(self->_number2month(Month))+' '+trim(string(Day))+', '+trim(string(Year))+')'
  endif

  ((self.plots)["HK"])[0]->setData, jd_data1, data1
  ((self.plots)["HK"])[1]->setData, jd_data2, data2
 
  ((self.plots)["HK"])[0]->Refresh

  self->_store_reset_position, ((self.plots)["HK"])[0]
end


;pro stx_HK_plotter::_update_plot_RCR
;
;  
;end

pro stx_HK_plotter_test::sync_plot, sel_graphics
     xrange = sel_graphics[0].xrange
     if (self.plots)->hasKey("HK") then (self.plots)["HK", 0].xrange = xrange
     if (self.plots)->hasKey("RCR") then (self.plots)["RCR", 0].xrange = xrange
end


pro stx_HK_plotter_test__define
  compile_opt idl2
  define = {stx_HK_plotter_test, $
      plot_types: list(), $
      JD_range: [0.d, 0.d], $
      inherits stx_plotter $
  }
end
