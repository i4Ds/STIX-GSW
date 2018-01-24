;+
; :description:
;    The stx_telemetry_reader structure is a container for the TM data and
;    information for the TM data management. It does not read data from disk
;    but from the TM packet in memory. Do not use directly, use stx_tmr.pro instead.
;
; :categories:
;    simulation, reader, telemetry
;
; :params:
;    buffer : in, type="byte array"
;             The data stream to read from
;
; :keywords:
;    id : in, optional, type="long", default="0L"
;             Assigns a unique id to this telemetry reader. The may id
;             will be used by stx_tmw
; :returns:
;    A telemetry reader struct is returned that contains the byte buffer (stream) and
;    according position pointers
;
; :examples:
;    tmr = stx_telemetry_reader(tmstream)
;
; :history:
;    11-Apr-2013 - Nicky Hochmuth (FHNW), initial release
;    22-Sep-2016 - Simon Marcin (FHNW), added getdata procedure. Refactoring: use intermediate format.
;    14-Oct-2016 - Simon Marcin (FHNW), added state to reader object. Multiple getData calls are now possible.
;-

function stx_telemetry_reader::init, stream=stream, filename=filename, buffersize=buffersize, scan_mode=scan_mode
  default, scan_mode, 0

    self.all_solo_packets   = HASH()
    self.stats_packets      = HASH()
    self.stats_structs      = HASH()
    self.solo_start         = HASH()
    self.statistics         = HASH()
    self.start_times        = HASH()

    status = self->stx_bitstream_reader::init(stream=stream, filename=filename, buffersize=buffersize)
    
    if scan_mode then begin
    start_packet_pos = 0
      while (self->have_data()) do begin
        solo_packet = self.read_packet_structure_source_packet_header(/scan_mode, $
          type=type, next_packet_pos=next_packet_pos)
        
        if n_elements(solo_packet) gt 0 then begin
          ; create list if fist packet of this type
          if (not self.solo_start.haskey(type)) then (self.solo_start)[type] = list()
          
          (self.solo_start)[type].add, start_packet_pos
          start_packet_pos = next_packet_pos
          ;print, type
          self->update_statistics, solo_packet=solo_packet, type=type
        endif
        
      endwhile
    endif
    
    self->create_statistics
    
    return, status
end


pro stx_telemetry_reader::update_statistics, solo_packet=solo_packet, type=type
  ; temp variables for shorter code
  seq_flag = solo_packet.segmentation_grouping_flags

  ; create an entry in the dicts if needed
  if (not self.stats_structs.haskey(type)) then begin
    (self.stats_packets)[type] = list()
    (self.start_times)[type] = list()
    (self.stats_structs)[type] = 0
  endif

  ; create a new list entry if we have a new packet_sequence or a standalone packet
  if(seq_flag eq 3 or seq_flag eq 1 or (type eq 'stx_tmtc_ql_calibration_spectrum')) then begin
    ; create new entry
    ((self.stats_packets)[type]).add, 1
    stx_telemetry_util_time2scet, coarse_time=solo_packet.coarse_time, fine_time=solo_packet.fine_time, $
      stx_time_obj=stx_time_obj, /reverse
    ((self.start_times)[type]).add, stx_time2any(stx_time_obj, /VMS)
    (self.stats_structs)[type] = (self.stats_structs)[type] + 1
  endif else begin
    ; attach
((self.stats_packets)[type])[-1]  = ((self.stats_packets)[type])[-1] + 1
  endelse
end


pro stx_telemetry_reader::update_packets,type=type
  ; if there are no solo_packets then we are in scan_mode
  if not (self.all_solo_packets.haskey(type)) then begin
    foreach start_byte, (self.solo_start)[type] do begin
      solo_packet = self.read_packet_structure_source_packet_header(start_byte=start_byte, type=type)
      self->add_solo,solo_packet=solo_packet,type=type
    endforeach
  endif
end


pro stx_telemetry_reader::add_solo,solo_packet=solo_packet,type=type

  ; create an entry in the dicts if needed
  if (not self.all_solo_packets.haskey(type)) then begin
    (self.all_solo_packets)[type] = list()
  endif
  
  ; create a new list entry if we have a new packet_sequence or a standalone packet
  seq_flag = solo_packet.segmentation_grouping_flags
  if(seq_flag eq 3 or seq_flag eq 1 or (type eq 'stx_tmtc_ql_calibration_spectrum')) then begin
    ; create new entry
    (self.all_solo_packets)[type].add, list(solo_packet)
  endif else begin
    ; attach
    ((self.all_solo_packets)[type])[-1].add,  solo_packet
  endelse
  
end

pro stx_telemetry_reader::getdata, $
  asw_hc_regular_mini = asw_hc_regular_mini, $
  asw_hc_regular_maxi = asw_hc_regular_maxi, $
  asw_hc_heartbeat = asw_hc_heartbeat, $
  asw_ql_lightcurve = asw_ql_lightcurve, $
  fsw_m_calibration_spectrum=fsw_m_calibration_spectrum, $
  asw_ql_calibration_spectrum=asw_ql_calibration_spectrum, $
  asw_ql_variance=asw_ql_variance, $
  asw_ql_flare_list=asw_ql_flare_list, $
  fsw_m_ql_spectra = fsw_m_ql_spectra, $
  fsw_m_sd_aspect = fsw_m_sd_aspect, $
  asw_ql_flare_flag_location=asw_ql_flare_flag_location, $
  asw_ql_background_monitor=asw_ql_background_monitor, $
  fsw_m_coarse_flare_locator=fsw_m_coarse_flare_locator, $
  fsw_m_flare_flag=fsw_m_flare_flag,$
  fsw_archive_buffer_time_group=fsw_archive_buffer_time_group, $
  fsw_pixel_data_time_group=fsw_pixel_data_time_group, $
  fsw_pixel_data_summed_time_group=fsw_pixel_data_summed_time_group, $
  fsw_spc_data_time_group = fsw_spc_data_time_group, $
  fsw_visibility_time_group = fsw_visibility_time_group, $
  bulk_data = bulk_data, $
  statistics = statistics, $
  solo_packets = solo_packets, $
  scan_mode=scan_mode, _extra=extra
  

  ; read all packets (we are not in scan_mode)
  while (self->have_data()) do begin
    solo_packet = self.read_packet_structure_source_packet_header(type=type)
    if(~isvalid(solo_packet)) then return
    if n_elements(solo_packet) gt 0 then begin
      self->update_statistics, solo_packet=solo_packet, type=type
      self->add_solo,solo_packet=solo_packet,type=type
      self->create_statistics
    endif
  endwhile
  
  
  ; ------------------------------------------------------------------------------
  ; create the requested output sructures
  
  ; bulk_data returns all structres as hash
   if(arg_present(bulk_data)) then begin
    bulk_data=HASH()
    
    self->getdata, asw_hc_regular_mini=asw_hc_regular_mini
    bulk_data['asw_hc_regular_mini']=asw_hc_regular_mini
    self->getdata, asw_hc_regular_maxi=asw_hc_regular_maxi
    bulk_data['asw_hc_regular_maxi']=asw_hc_regular_maxi
    self->getdata, asw_hc_heartbeat=asw_hc_heartbeat
    bulk_data['asw_hc_heartbeat']=asw_hc_heartbeat
    self->getdata, asw_ql_lightcurve=asw_ql_lightcurve
    bulk_data['asw_ql_lightcurve']=asw_ql_lightcurve
    self->getdata, asw_ql_flare_flag_location=asw_ql_flare_flag_location
    bulk_data['asw_ql_flare_flag_location']=asw_ql_flare_flag_location
    self->getdata, asw_ql_variance=asw_ql_variance
    bulk_data['asw_ql_variance']=asw_ql_variance
    self->getdata, asw_ql_flare_list=asw_ql_flare_list
    bulk_data['asw_ql_flare_list']=asw_ql_flare_list
    self->getdata, fsw_m_ql_spectra=fsw_m_ql_spectra
    bulk_data['fsw_m_ql_spectra']=fsw_m_ql_spectra
    self->getdata, fsw_m_sd_aspect=fsw_m_sd_aspect
    bulk_data['fsw_m_sd_aspect']=fsw_m_sd_aspect
    self->getdata, asw_ql_background_monitor=asw_ql_background_monitor
    bulk_data['asw_ql_background_monitor']=asw_ql_background_monitor
    self->getdata, asw_ql_calibration_spectrum=asw_ql_calibration_spectrum
    bulk_data['asw_ql_calibration_spectrum']=asw_ql_calibration_spectrum
    self->getdata, fsw_archive_buffer_time_group=fsw_archive_buffer_time_group
    bulk_data['fsw_archive_buffer_time_group']=fsw_archive_buffer_time_group
    self->getdata, fsw_pixel_data_time_group=fsw_pixel_data_time_group
    bulk_data['fsw_pixel_data_time_group']=fsw_pixel_data_time_group
    self->getdata, fsw_pixel_data_summed_time_group=fsw_pixel_data_summed_time_group
    bulk_data['fsw_pixel_data_summed_time_group']=fsw_pixel_data_summed_time_group
    self->getdata, fsw_visibility_time_group=fsw_visibility_time_group
    bulk_data['fsw_visibility_time_group']=fsw_visibility_time_group
    self->getdata, fsw_spc_data_time_group=fsw_spc_data_time_group
    bulk_data['fsw_spc_data_time_group']=fsw_spc_data_time_group
    
    ; solo_packets
    if(arg_present(solo_packets)) then solo_packets = self.all_solo_packets
    ; statistics
    if(arg_present(statistics)) then statistics=self.statistics
    
    ; we already have all data products therefore we return
    return
  endif
  
  ; stx_asw_regular_mini
  if(arg_present(asw_hc_regular_mini)) then begin
    type = 'stx_tmtc_hc_regular_mini'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_hc_regular_mini = list()
      for idx = 0L, self.stats_structs[type]-1 do begin
         stx_telemetry_prepare_structure_hc_regular_mini, solo_slices=((self.all_solo_packets)[type])[idx], $
          report_mini=report_mini
          asw_hc_regular_mini.add, report_mini
      endfor
    endif
  endif

  ; stx_asw_regular_maxi
  if(arg_present(asw_hc_regular_maxi)) then begin
    type = 'stx_tmtc_hc_regular_maxi'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_hc_regular_maxi = list()
      for idx = 0L, self.stats_structs[type]-1 do begin
        stx_telemetry_prepare_structure_hc_regular_maxi, solo_slices=((self.all_solo_packets)[type])[idx], $
          report_maxi=report_maxi
        asw_hc_regular_maxi.add, report_maxi
      endfor
    endif
  endif

  ; asw_hc_heartbeat
  if(arg_present(asw_hc_heartbeat)) then begin
    type = 'stx_tmtc_hc_heartbeat'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_hc_heartbeat = list()
      for idx = 0L, self.stats_structs[type]-1 do begin
        stx_telemetry_prepare_structure_hc_heartbeat, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_hc_heartbeat=heartbeat
        asw_hc_heartbeat.add, heartbeat
      endfor
    endif
  endif
  
  ; stx_asw_ql_lightcurve
  if(arg_present(asw_ql_lightcurve)) then begin
    type = 'stx_tmtc_ql_light_curves'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_ql_lightcurve = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_light_curves, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_ql_lightcurve=ql_lightcurve, _extra=extra
        asw_ql_lightcurve.add, ql_lightcurve
      endfor
    endif
  endif

  ; asw_ql_flare_flag_location
  if(arg_present(asw_ql_flare_flag_location)) then begin
    type = 'stx_tmtc_ql_flare_flag_location'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_ql_flare_flag_location = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_flare_flag_location, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_ql_flare_flag_location=ql_flare_flag_location, _extra=extra
        asw_ql_flare_flag_location.add, ql_flare_flag_location
      endfor
    endif
  endif
  
  ; fsw_m_coarse_flare_locator or fsw_m_flare_flag
  if(arg_present(fsw_m_flare_flag) or arg_present(fsw_m_coarse_flare_locator)) then begin
    type = 'stx_tmtc_ql_flare_flag_location'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_m_flare_flag = list()
      fsw_m_coarse_flare_locator = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_flare_flag_location, solo_slices=((self.all_solo_packets)[type])[idx], $
              fsw_m_coarse_flare_locator=flare_locator, $
              fsw_m_flare_flag=flare_flag, _extra=extra
        fsw_m_coarse_flare_locator.add, flare_locator
        fsw_m_flare_flag.add, flare_flag
      endfor
    endif
  endif

  ; asw_ql_variance
  if(arg_present(asw_ql_variance)) then begin
    type = 'stx_tmtc_ql_variance'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_ql_variance = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_variance, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_ql_variance=ql_variance, _extra=extra
        asw_ql_variance.add, ql_variance
      endfor
    endif
  endif

  ; asw_ql_flare_list
  if(arg_present(asw_ql_flare_list)) then begin
    type = 'stx_tmtc_ql_flare_list'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_ql_flare_list = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_flare_list, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_ql_flare_list=ql_flare_list, _extra=extra
        asw_ql_flare_list.add, ql_flare_list
      endfor
    endif
  endif

  ; fsw_m_ql_spectra
  if(arg_present(fsw_m_ql_spectra)) then begin
    type = 'stx_tmtc_ql_spectra'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_m_ql_spectra = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_spectra, solo_slices=((self.all_solo_packets)[type])[idx], $
          fsw_m_ql_spectra=ql_spectra, _extra=extra
        fsw_m_ql_spectra.add, ql_spectra
      endfor
    endif
  endif

  ; fsw_m_sd_aspect
  if(arg_present(fsw_m_sd_aspect)) then begin
    type = 'stx_tmtc_sd_aspect'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_m_sd_aspect = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_sd_aspect, solo_slices=((self.all_solo_packets)[type])[idx], $
          stx_fsw_m_aspect=sd_aspect, _extra=extra
        fsw_m_sd_aspect.add, sd_aspect
      endfor
    endif
  endif
  
  ; asw_ql_background_monitor
  if(arg_present(asw_ql_background_monitor)) then begin
    type = 'stx_tmtc_ql_background_monitor'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_ql_background_monitor = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_background_monitor, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_ql_background_monitor=ql_background_monitor, _extra=extra
        asw_ql_background_monitor.add, ql_background_monitor
      endfor
    endif
  endif

  ; asw_ql_calibration_spectrum or fsw_m_calibration_spectrum
  if(arg_present(asw_ql_calibration_spectrum) or arg_present(fsw_m_calibration_spectrum)) then begin
    type = 'stx_tmtc_ql_calibration_spectrum'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      asw_ql_calibration_spectrum = list()
      fsw_m_calibration_spectrum = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_ql_calibration_spectrum, solo_slices=((self.all_solo_packets)[type])[idx], $
          asw_ql_calibration_spectrum=ql_calibration_spectrum, $
          fsw_m_calibration_spectrum=m_calibration_spectrum, _extra=extra
        if arg_present(asw_ql_calibration_spectrum) then asw_ql_calibration_spectrum.add, ql_calibration_spectrum
        if arg_present(fsw_m_calibration_spectrum) then stop; WHY are we offering both? This one is not working,...fsw_m_calibration_spectrum.add, m_calibration_spectrum
      endfor
    endif
  endif

  ; fsw_archive_buffer_time_group
  if(arg_present(fsw_archive_buffer_time_group)) then begin
    type = 'stx_tmtc_sd_xray_0'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_archive_buffer_time_group = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_sd_xray_0, solo_slices=((self.all_solo_packets)[type])[idx], $
          fsw_archive_buffer_time_group=archive_buffer_time_group, _extra=extra
        fsw_archive_buffer_time_group.add, archive_buffer_time_group
      endfor
    endif
  endif

  ; fsw_pixel_data_time_group
  if(arg_present(fsw_pixel_data_time_group)) then begin
    type = 'stx_tmtc_sd_xray_1'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_pixel_data_time_group = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_sd_xray_1, solo_slices=((self.all_solo_packets)[type])[idx], $
          fsw_pixel_data_time_group=pixel_data_time_group, _extra=extra
        fsw_pixel_data_time_group.add, pixel_data_time_group
      endfor
    endif
  endif
  
  ; fsw_pixel_data_summed_time_group
  if(arg_present(fsw_pixel_data_summed_time_group)) then begin
    type = 'stx_tmtc_sd_xray_2'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_pixel_data_summed_time_group = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_sd_xray_1, solo_slices=((self.all_solo_packets)[type])[idx], $
          fsw_pixel_data_summed_time_group=pixel_data_summed_time_group, /lvl_2, _extra=extra
        fsw_pixel_data_summed_time_group.add, pixel_data_summed_time_group
      endfor
    endif
  endif
  
  ; fsw_visibility_time_group
  if(arg_present(fsw_visibility_time_group)) then begin
    type = 'stx_tmtc_sd_xray_3'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_visibility_time_group = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_sd_xray_3, solo_slices=((self.all_solo_packets)[type])[idx], $
          fsw_visibility_time_group=visibility_time_group, _extra=extra
        fsw_visibility_time_group.add, visibility_time_group
      endfor
    endif
  endif
  
  ; fsw_spc_data_time_group
  if(arg_present(fsw_spc_data_time_group)) then begin
    type = 'stx_tmtc_sd_spectrogram'
    if(self.stats_packets.haskey(type)) then begin
      self->update_packets,type=type
      fsw_spc_data_time_group = list()
      for idx = 0L, ((self.stats_structs)[type])-1 do begin
        stx_telemetry_prepare_structure_sd_spectrogram, solo_slices=((self.all_solo_packets)[type])[idx], $
          fsw_spc_data_time_group=spc_data_time_group, _extra=extra
        fsw_spc_data_time_group.add, spc_data_time_group
      endfor
    endif
  endif


  ; solo_packets
  if(arg_present(solo_packets)) then solo_packets = self.all_solo_packets

  ; statistics
  if(arg_present(statistics)) then statistics=self.statistics
     
end


pro stx_telemetry_reader::create_statistics

  ; create a new dict which holds stx_telemetry_packet_statistics
  foreach key, self.stats_structs.keys() do begin
    (self.statistics)[key] = list()
    
    for i=0L, n_elements((self.stats_packets)[key])-1  do begin

      stat = stx_telemetry_statistics(key,((self.start_times)[key])[i])
      stat.nbr_of_packets = ((self.stats_packets)[key])[i]
      ((self.statistics)[key]).add, stat
    endfor

  endforeach

end


function stx_telemetry_reader::read_packet_structure_source_packet_header, scan_mode=scan_mode, $
  type=type, next_packet_pos=next_packet_pos, start_byte=start_byte
  default, scan_mode, 0
  
  ; if we get a start_byte we jump to this position
  if n_elements(start_byte) ne 0 then begin
    old_byteptr = self.byteptr
    self.byteptr = start_byte
  endif

  ;write down start byte position of each solo_packet
  if n_elements(start_byte) eq 0 then self.start_positions.add, self.byteptr
  ;print, self.byteptr

  ; generate empty solo packet
  solo_packet = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read tmtc mapping file
  mappings = stx_read_tmtc_mapping()

  ; auto-read common headers
  self->auto_read_structure, packet=solo_packet, tag_ignore=['type', 'pkg_.*', 'source_data']

  ; peek next 8 bits to get sid/ssid
  sid_ssid = self->read(size(uint(0), /type), bits=8, debug=debug, silent=silent, /peek)
  ;sid_ssid = self->peek(size(uint(0), /type), bits=8, debug=debug, silent=silent)

  ; find candidates
  candidate_id = where(mappings.packet_category eq solo_packet.packet_category and $
    mappings.pid eq solo_packet.pid and $
    mappings.service_type eq solo_packet.service_type and $
    mappings.service_subtype eq solo_packet.service_subtype and $
    (mappings.sid eq sid_ssid or mappings.ssid eq sid_ssid), n_candidates)
    
  ; fail on incorrect id
  ; TODO choose the fail action
  if(candidate_id eq -1) then begin
    message, 'No suitable STIX telemetry packet found.', /info
    return, !NULL
  endif
  

  candidate = mappings[candidate_id]
  type=candidate.STX_TMTC_STR
  
  ;scan_mode = 1
  if scan_mode then begin  
    
    ; substract 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
    offset_data_header = 9
    
    ;extract information about this and next packet_start_pos
    next_packet_pos = (self.byteptr+solo_packet.DATA_FIELD_LENGTH-offset_data_header)
    
    ;advance pointer and return
    if self.byteptr +solo_packet.DATA_FIELD_LENGTH ge self.buffersize then begin
      self.byteptr = self.buffersize
    endif else self.byteptr +=solo_packet.DATA_FIELD_LENGTH-offset_data_header
    return, solo_packet
  endif


  ; select appropriate reading routine
  switch (candidate.stx_tmtc_str) of
    'stx_tmtc_ql_calibration_spectrum': begin
      tmtc_data = stx_telemetry_read_ql_calibration_spectrum(solo_packet=solo_packet, tmr=self, _extra=extra) 
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_ql_light_curves': begin
      tmtc_data = stx_telemetry_read_ql_light_curves(solo_packet=solo_packet, tmr=self, _extra=extra)  
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end    
    'stx_tmtc_ql_spectra': begin
      tmtc_data = stx_telemetry_read_ql_spectra(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_ql_variance': begin
      tmtc_data = stx_telemetry_read_ql_variance(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_ql_background_monitor': begin
      tmtc_data = stx_telemetry_read_ql_background_monitor(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_ql_flare_flag_location': begin
      tmtc_data = stx_telemetry_read_ql_flare_flag_location(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_ql_flare_list': begin
      tmtc_data = stx_telemetry_read_ql_flare_list(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_hc_heartbeat': begin
      tmtc_data = stx_telemetry_read_hc_heartbeat(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_hc_regular_mini': begin
      tmtc_data = stx_telemetry_read_hc_regular_mini(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_hc_regular_maxi': begin
      tmtc_data = stx_telemetry_read_hc_regular_maxi(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_sd_xray_0': begin
      tmtc_data = stx_telemetry_read_sd_xray_0(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_sd_xray_1': begin
      tmtc_data = stx_telemetry_read_sd_xray_1(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end     
    'stx_tmtc_sd_xray_2': begin
      tmtc_data = stx_telemetry_read_sd_xray_1(solo_packet=solo_packet, tmr=self, /lvl_2, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_sd_xray_3': begin
      tmtc_data = stx_telemetry_read_sd_xray_3(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    'stx_tmtc_sd_spectrogram': begin
      tmtc_data = stx_telemetry_read_sd_spectrogram(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end  
    'stx_tmtc_sd_aspect': begin
      tmtc_data = stx_telemetry_read_sd_aspect(solo_packet=solo_packet, tmr=self, _extra=extra)
      solo_packet.source_data = ptr_new(tmtc_data)
      break
    end
    else: begin
    end
  endswitch
  
  ; if we get a start_byte we reset the byteptr to its old value again
  if n_elements(start_byte) ne 0 then begin
    self.byteptr = old_byteptr
  endif
  
  return, solo_packet
end


; auto_populate_fields
pro stx_telemetry_reader::auto_read_structure, packet=packet, tag_ignore=tag_ignore
  default, tag_ignore, ['type', 'pkg_.*', 'header_.*']

  tag_ignore_regex = arr2str('^' + tag_ignore + '$', delimiter='|')

  tags = strlowcase(tag_names(packet))

  for tag_idx = 0L, n_tags(packet)-1 do begin
    tag = tags[tag_idx]

    if(total(stregex(tag, tag_ignore_regex, /boolean) ne 0) gt 0) then continue

    tag_len = packet.pkg_word_width.(tag_index(packet.pkg_word_width, tag))
    tag_val = packet.(tag_idx)
    
    packet.(tag_idx) = self->read(size(tag_val, /type), bits=tag_len, debug=debug, silent=silent)

  endfor
end

pro stx_telemetry_reader::auto_override_common_fields, solo_packet=solo_packet, data_packet=data_packet
  tag_use = '^header_(.*)$'

  tags = strlowcase(tag_names(data_packet))

  for tag_idx = 0L, n_tags(data_packet)-1 do begin
    tag_data_packet = tags[tag_idx]

    if(~stregex(tag_data_packet, tag_use, /boolean))then continue

    tag_solo_packet = (stregex(tag_data_packet, tag_use, /extract, /subexpr))[1]

    data_packet.(tag_idx) = solo_packet.(tag_index(solo_packet, tag_solo_packet))
  endfor
end

function stx_telemetry_reader::archive_buffer, no_entries
  ab = replicate({stx_fsw_archive_buffer}, 32, 32, 12)



  for i=0, no_entries-1 do begin
    detector_index = self->read(1,BITS=5)
    energy_science_channel = self->read(1,BITS=5)
    pixel_index = self->read(1,BITS=4)

    cb = self->read(1,BITS=2) / 2 ;read cb and sb at ones und shift back
    counts = cb eq 1 ? self->read(1,BITS=8) : 1b

    ab[detector_index,energy_science_channel,pixel_index].detector_index = detector_index + 1
    ab[detector_index,energy_science_channel,pixel_index].energy_science_channel = energy_science_channel
    ab[detector_index,energy_science_channel,pixel_index].pixel_index = pixel_index
    ab[detector_index,energy_science_channel,pixel_index].counts += counts
  end

  valid = where(ab.counts gt 0, count_valid)

  return, count_valid gt 0 ? ab[valid] : -1
end

function stx_telemetry_reader::science_header_science_data, ssid

  h = stx_telemetry_shsd()

  bits_for_no_sub_structures = 16

  case ssid of
     5: bits_for_no_sub_structures = 16
    10: bits_for_no_sub_structures = 16
    11: bits_for_no_sub_structures = 5
    12: bits_for_no_sub_structures = 16
    13: bits_for_no_sub_structures = 16
    else: begin
      message, 'Unrecognized science data sample type.'
    end
  endcase

  h.ssid = ssid
  h.deltatimeseconds = self->read(2,BITS=16)
  h.deltatimesubseconds = self->read(12,bits=10)
  h.ratecontrolregime = self->read(1,bits=4)
  h.numbersubstructures = self->read(12,BITS=bits_for_no_sub_structures)
  h.pixelmask = stx_mask2bits(self->read(12,bits=12), /reverse, mask_length=12)

  spare = self->read(12,BITS=6)

  h.detectorsmask = stx_mask2bits(self->read(13,BITS=32), /reverse, mask_length=32)
  h.coarseflarelocation = [self->read(1,BITS=8), self->read(1,BITS=8)]

  for i=0, 15 do h.livetimeaccumulator[i]=self->read(12,BITS=16)

  case ssid of
    10: data = self->archive_buffer(h.numbersubstructures)
    11: data = -1
    12: data = -1
    13: data = -1
  endcase

  h = add_tag(h,data,"data")

  return, h
end


pro stx_telemetry_reader__define
  compile_opt idl2, hidden

  ; create stx_telemetry_reader structure that contains all information
  ; for the tm data reading process
  void = { stx_telemetry_reader, $
    all_solo_packets   : HASH(), $
    stats_packets      : HASH(), $
    stats_structs      : HASH(), $
    solo_start         : HASH(), $
    statistics         : HASH(), $
    start_times        : HASH(), $
    inherits stx_bitstream_reader }
end
