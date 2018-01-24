
;+
; :description:
;    this function initialises this module
;
; :params:
;    configuration_manager : in, optional, type='string', default="stx_configuration_manager(configfile='stx_data_simulation_default.config')"
;      this is a stx_configuration_manager object that has been
;      initialized with a stx_data_simulation configuration
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_telemetry_generator::init, configuration_manager
  default, configuration_manager, stx_configuration_manager(application_name='stx_telemetry_generator')
  res = self->ppl_processor::init(configuration_manager)
  return, res
end

;+
; :description:
;    this is the main processing routine; data can be requested by providing 'input_data'
;    and specifying the desired 'output_target'
;-
function stx_telemetry_generator::getdata, input_data=input_data, output_target=output_target, start_time=start_time, end_time=end_time, ssid=ssid, _extra=extra
  
  ; detect level of this call on stack
  help, /traceback, out=tb
  ; only install error handler if this routine has not been previously called
  ppl_state_info, out_filename=this_file_name
  found = where(stregex(tb, this_file_name) ne -1, level)

  if(level -1 eq 0) then begin
    ; activate error handler
    ; setup debugging and flow control
    mod_global = self->get(module='global')
    debug = mod_global.debug
    stop_on_error = mod_global.stop_on_error
    !EXCEPT = mod_global.math_error_level

    ; make sure we start fresh
    message, /reset

    ; install error handler if no stop_on_error is set; otherwise skip and let IDL stop where
    ; the error occurred
    if(~stop_on_error) then begin
      error = 0
      catch, error
      if(error ne 0) then begin
        catch, /cancel
        help, /last_message, out=last_message
        error = ppl_construct_error(message=last_message, /parse)
        ppl_print_error, error
        return, error
      endif
    endif
  endif
  
  fsw = input_data
  
  ppl_require, in=fsw, TYPE='stx_flight_software_simulator'
  
  
  tm_packages = list() 
  
  fsw->getProperty, start_time=fsw_start_time, current_time=fsw_end_time 
  
  default, start_time, fsw_start_time
  default, end_time, fsw_end_time
  
  default, output_target, 'ql'

  switch STRLOWCASE(output_target) of
    'ql': begin
      self->generate_ql, fsw, tm_packages, start_time, end_time, ssid=ssid, _extra=extra 
      break
    end
    'hk': begin
      self->generate_hk, fsw, tm_packages, start_time, end_time, ssid=ssid, _extra=extra 
      break
    end
    'sd': begin
      self->generate_sd, fsw, tm_packages, start_time, end_time, ssid=ssid, _extra=extra 
      break
    end
    else: begin
      message, 'Unknown output_target'
    end
  endswitch
  
  ;tmw->flushtofile
  return, tm_packages->ToArray()
  
end

function stx_telemetry_generator::_new_sd_package, tm_packages, ssid=ssid, time=time
  COMPILE_OPT hidden
  tm_packages->add, stx_telemetry_writer(size=self->get(/sd_max_package_size))
  return, (tm_packages[-1])->science_package_header(ssid=ssid, time=time)
end

function stx_telemetry_generator::_append_sd_package, tm_packages, tmw , n_sd, package_header_gap_positions, ssid=ssid, time=time
  COMPILE_OPT hidden
  
  current_writer = tm_packages[-1]
  
  
  
  new_buffer = tmw->getBuffer(/trim)
  new_buffer_size = N_ELEMENTS(new_buffer)
  if  new_buffer_size gt 0 then begin
    cp = current_writer->getPosition()
    if cp[0] + 1 + new_buffer_size gt current_writer.size then begin
      ;finich the packege header by fill in the gaps
      current_writer->finalize_science_package_header, package_header_gap_positions, n_sd
      void = self->_new_sd_package(tm_packages, ssid=ssid, time=time)
      ;get the latest writer
      current_writer = tm_packages[-1]
      n_sd=0
    endif 
    current_writer->write,new_buffer, bits=8, /extract
    n_sd++ 
   
  endif
  
  return, n_sd
end


pro stx_telemetry_generator::generate_sd, fsw, tm_packages, start_time, end_time, ssid = ssid, _extra=extra
  
  ;ensure to have all data available
  old_compaction_level = fsw->get(/dcom_max_compression_level)
  fsw->set, dcom_max_compression_level=4
  
  ;get the science data
  flaredata = fsw->getData(output_target='stx_fsw_ivs_result')
  
  ref_time = fsw.start_time
  max_size = self->get(/sd_max_package_size)
  ab_split_size = self->get(/sd_ab_split_size)
  
  package_header_gap_positions = self->_new_sd_package(tm_packages, ssid=ssid, time=ref_time)
  
  n_sd = 0L
  
  foreach flare, flaredata, flare_idx do begin
    help, flare
    
    if stx_time_lt(flare.FLARE_TIME[0], start_time) || stx_time_gt(flare.FLARE_TIME[1], end_time) then begin
      message, "skip flare", /CONTINUE
      continue
    endif
      
      case (ssid) of
        !STX_TM_SID.SD_ARCHIVE_BUFFER: begin
         
          print, 'write AB to TM: ', "flare, group, chunk, start, end, max"
          
          foreach tgroup, flare.L0_ARCHIVE_BUFFER_GROUPED, tgroup_idx do begin
            n_entry = N_ELEMENTS(tgroup.ARCHIVE_BUFFER)
            for i=0, (n_entry/ab_split_size) do begin
              
              tmw = stx_telemetry_writer(size=max_size*100)
              start_idx = i*ab_split_size
              end_idx = min([start_idx+ab_split_size,n_entry])
              print, [flare_idx, tgroup_idx, i, start_idx, end_idx, n_entry]
              if end_idx eq start_idx then break
             
              data = tgroup.ARCHIVE_BUFFER[start_idx:end_idx-1]
              tmw->science_header_science_data, data, ssid, $
                delta_time      = stx_time_diff(tgroup.START_TIME, tgroup.END_TIME, /abs), $
                rc_regime       = tgroup.RCR, $
                pixel_mask      = tgroup.PIXEL_MASK, $
                cfl             = tgroup.CFL, $
                detector_mask   = tgroup.DETECTOR_MASK, $
                livetime        = tgroup.LIVETIME
                
              n_sd = self->_append_sd_package(tm_packages, tmw, n_sd, package_header_gap_positions)  
            endfor ;split
          endforeach ;group
        end

        !STX_TM_SID.SD_PIXELS: begin
          foreach tgroup, flare.L1_IMG_COMBINED_ARCHIVE_BUFFER_GROUPED do begin
            tmw = stx_telemetry_writer(size=max_size)
            tmw->science_header_science_data, tgroup.Intervals, ssid, $
              delta_time      = stx_time_diff(tgroup.START_TIME, tgroup.END_TIME, /abs), $
              rc_regime       = tgroup.RCR, $
              pixel_mask      = tgroup.PIXEL_MASK, $
              cfl             = tgroup.CFL, $
              detector_mask   = tgroup.DETECTOR_MASK, $
              livetime        = tgroup.LIVETIME

            n_sd = self->_append_sd_package(tm_packages, tmw, n_sd, package_header_gap_positions)
          endforeach
        end

        !STX_TM_SID.SD_SUMMEDPIXELS : begin
          foreach tgroup, flare.L2_IMG_COMBINED_PIXEL_SUMS_GROUPED do begin
            tmw = stx_telemetry_writer(size=max_size)
            tmw->science_header_science_data, tgroup.Intervals, ssid, $
              delta_time      = stx_time_diff(tgroup.START_TIME, tgroup.END_TIME, /abs), $
              rc_regime       = tgroup.RCR, $
              pixel_mask      = tgroup.PIXEL_MASK, $
              cfl             = tgroup.CFL, $
              detector_mask   = tgroup.DETECTOR_MASK, $
              livetime        = tgroup.LIVETIME

            n_sd = self->_append_sd_package(tm_packages, tmw, n_sd, package_header_gap_positions)
          endforeach
        end

        !STX_TM_SID.SD_VIESIBILITIES: begin
          foreach tgroup, flare.L3_IMG_COMBINED_VISIBILITY_GROUPED do begin
            tmw = stx_telemetry_writer(size=max_size)
            tmw->science_header_science_data, tgroup.Intervals, ssid, $
              delta_time      = stx_time_diff(tgroup.START_TIME, tgroup.END_TIME, /abs), $
              rc_regime       = tgroup.RCR, $
              pixel_mask      = tgroup.PIXEL_MASK, $
              cfl             = tgroup.CFL, $
              detector_mask   = tgroup.DETECTOR_MASK, $
              livetime        = tgroup.LIVETIME

            n_sd = self->_append_sd_package(tm_packages, tmw, n_sd, package_header_gap_positions)
          endforeach
        end
        
        else: begin
          MESSAGE, "ssid not supported"
        end
      endcase
      

  endforeach
  
  fsw->set, dcom_max_compression_level=old_compaction_level
  
  if n_sd gt 0 then begin
    ;finich the packege header by fill in the gaps
    tm_packages[-1]->finalize_science_package_header, package_header_gap_positions, n_sd
  end else begin
    tm_packages->remove, -1
  end
end 

pro stx_telemetry_generator::generate_ql, fsw, tmw, start_time, end_time, ssid=ssid, _extra=extra 
  cfg = self->get(module="quicklook")
  
  ql_data = fsw.ql_data
  
  max_size = self->get(ql_max_package_size)
  
  case (ssid) of
    !STX_TM_SID.QL_VARIANCE: begin
      var = self->_time_trim(fsw.variance, start_time, end_time, dim=1)

      help, var, /str
    end
    
    !STX_TM_SID.QL_LIGHTCURVE: begin
      lc = self->_time_trim(ql_data['stx_fsw_ql_lightcurve'], start_time, end_time, dim=4,/ql)
      lc_lt = self->_time_trim(ql_data['stx_fsw_ql_lightcurve_lt'], start_time, end_time, dim=4,/ql)
      rcr = self->_time_trim(fsw.rate_control, start_time, end_time, dim=1)

      ;TODO N.H. Detector mask?
      ;TODO N.H. Pixel mask obsolet due to rcr?

      lc = add_tag(lc, lc_lt.accumulated_counts, 'trigger')
      lc = add_tag(lc, rcr.data, 'rcr')

      help, lc, /str
    end
    
    !STX_TM_SID.QL_FLARE_FLAG: begin
      ff = self->_time_trim(fsw.flare_flag, start_time, end_time, dim=1)
      cfl = self->_time_trim(fsw.coarse_flare_location, start_time, end_time, dim=1)
      help, ff, cfl, /str
    end
    
    !STX_TM_SID.QL_DETECTOR_CALIBRATION: begin
      
    end
    
    !STX_TM_SID.QL_SPECTRA: begin
      dc = self->_time_trim(ql_data['stx_fsw_ql_quicklook'], start_time, end_time, dim=4,/ql)
      dc_lt = self->_time_trim(ql_data['stx_fsw_ql_quicklook_lt'], start_time, end_time, dim=4,/ql)

      ;TODO N.H. review muxing
      ;mux the data in a 32er loop
      n_times = n_elements(dc.time_axis.duration)

      ;TODO N.H. check how the ltpair behaves

      mux_idx_det = (reproduce(lindgen(32),(n_times / 32) + 1 ))[0:n_times-1]
      mux_idx = mux_idx_det + (lindgen(n_times)*32)
      muxed_tiggers = reform(dc_lt.accumulated_counts[mux_idx],1,1,1,n_times)

      muxed_det_counts = ULONARR(32,1,1,n_times)
      for t=0L, n_times-1 do muxed_det_counts[*,0,0,t]=dc.accumulated_counts[*,0,mux_idx_det[t], t]

      dc = ppl_replace_tag(dc, 'accumulated_counts', muxed_det_counts)
      dc = add_tag(dc, muxed_tiggers, 'trigger')
      dc = add_tag(dc, mux_idx, 'mux')

      help, dc, /str
    end
    
    !STX_TM_SID.QL_BACKGROUND: begin
      bkg = self->_time_trim(fsw.background, start_time, end_time, dim=1)
      help, bkg, /str
    end
    
    else: begin
       MESSAGE, "ssid not supported"
    end
  endcase
  
end

function stx_telemetry_generator::_time_trim, data, start_time, end_time, dim=dim, ql=ql
  default, dim, 1
  default, ql, 0
  
  trim_idx = stx_time_value_locate(data.time_axis.TIME_START, [start_time,end_time])
  
  triemed_data = ppl_replace_tag(data,"time_axis",stx_construct_time_axis(TIME_AXIS=data.time_axis, idx=trim_idx[0] + lindgen(trim_idx[1]-trim_idx[0]+1)))
  
  tag_name = ql ? "ACCUMULATED_COUNTS" : "data"
  tag_idx = tag_index(data,tag_name)
  
  if dim eq 1 then return, ppl_replace_tag(triemed_data,tag_name,data.(tag_idx)[trim_idx[0]:trim_idx[1]])
  if dim eq 4 then return, ppl_replace_tag(triemed_data,tag_name,data.(tag_idx)[*,*,*,trim_idx[0]:trim_idx[1]])

  
end

pro stx_telemetry_generator__define
  compile_opt hidden, idl2
  stx_tm_sid
  void = {  stx_telemetry_generator ,$
            inherits ppl_processor}
end