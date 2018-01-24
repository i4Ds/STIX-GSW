;+
; :description:
;    The stx_telemetry_writer object writes data into the telemetry format into memmory or into a file
;
; :categories:
;    simulation, writer, telemetry
;
; :params:
;    buffer : in, type="byte array"
;             The data stream to read from
;
; :keywords:
;    size : in, type="number"
;             The initial size of the buffer
;
;    filename : in, type="string"
;             name and path of the file for flushing the data
; :returns:
;    A telemetry reader struct is returned that contains the byte buffer (stream) and
;    according position pointers
;
; :examples:
;    tmr = stx_telemetry_reader(tmstream)
;
; :history:
;    11-Apr-2013 - Nicky Hochmuth (FHNW), initial release
;    11-Feb-2015 - Richard A. Schwartz (GSFC), fixed typos
;    19-Sep-2016 - Simon Marcin (FHNW), added setdata procedure, refactored the workflow of getting data
;
; :todo:
;    24-Apr-2013 - Nicky Hochmuth (FHNW), add auto flush for filemode and buffer-extension if the buffer is full

;-

function stx_telemetry_writer::init, size=size, filename=filename
  self.obt_counter=0L
  self.solo_packets = HASH()
  return, self->stx_bitstream_writer::init(size=size, filename=filename)
end


pro stx_telemetry_writer::setdata, $
  ql_calibration_spectrum = ql_calibration_spectrum, $
  ql_lightcurve = ql_lightcurve,  $
  ql_spectra = ql_spectra, $
  ql_lt_spectra=ql_lt_spectra, $
  ql_variance = ql_variance, $
  ql_background_monitor = ql_background_monitor, $
  ql_lt_background_monitor = ql_lt_background_monitor, $
  ql_flare_list = ql_flare_list, $
  ql_flare_flag = ql_flare_flag, $
  ql_flare_location = ql_flare_location, $
  hc_heartbeat = hc_heartbeat, $
  hc_regular_mini = hc_regular_mini, $
  hc_regular_maxi = hc_regular_maxi, $
  sd_xray_0 = sd_xray_0, sd_xray_1 = sd_xray_1, sd_xray_2 = sd_xray_2, $
  sd_xray_3 = sd_xray_3, sd_spc = sd_spc, $
  sd_aspect = sd_aspect, $
  bulk_data=bulk_data, $
  solo_packets = solo_packets, $
  _extra = extra
  
  
  ;call setdata again for each entry in the bulk_data has
  if(arg_present(bulk_data)) then begin
    if bulk_data.HasKey('ql_lightcurve') then self->setdata, ql_lightcurve=bulk_data['ql_lightcurve']
    if bulk_data.HasKey('hc_regular_mini') then self->setdata, hc_regular_mini=bulk_data['hc_regular_mini']
    if bulk_data.HasKey('hc_regular_maxi') then self->setdata, hc_regular_maxi=bulk_data['hc_regular_maxi']
    if bulk_data.HasKey('hc_heartbeat') then self->setdata, hc_heartbeat=bulk_data['hc_heartbeat']
    if bulk_data.HasKey('ql_flare_flag_location') then self->setdata, ql_flare_flag_location=bulk_data['ql_flare_flag_location']
    if bulk_data.HasKey('ql_flare_flag') then self->setdata, $
      ql_flare_flag=bulk_data['ql_flare_flag'], ql_flare_location=bulk_data['ql_flare_location']
    if bulk_data.HasKey('ql_variance') then self->setdata, ql_variance=bulk_data['ql_variance']
    if bulk_data.HasKey('ql_flare_list') then self->setdata, ql_flare_list=bulk_data['ql_flare_list']
    if bulk_data.HasKey('ql_spectra') then self->setdata, ql_spectra=bulk_data['ql_spectra']
    if bulk_data.HasKey('ql_background_monitor') then self->setdata, ql_background_monitor=bulk_data['ql_background_monitor']
    if bulk_data.HasKey('ql_calibration_spectrum') then self->setdata, ql_calibration_spectrum=bulk_data['ql_calibration_spectrum']
    if bulk_data.HasKey('sd_xray_0') then self->setdata, sd_xray_0=bulk_data['sd_xray_0']
    if bulk_data.HasKey('sd_xray_1') then self->setdata, sd_xray_1=bulk_data['sd_xray_1']
    if bulk_data.HasKey('sd_xray_2') then self->setdata, sd_xray_2=bulk_data['sd_xray_2']
    if bulk_data.HasKey('sd_xray_3') then self->setdata, sd_xray_3=bulk_data['sd_xray_3']
    if bulk_data.HasKey('sd_spc') then self->setdata, sd_spc=bulk_data['sd_spc']
    if bulk_data.HasKey('sd_aspect') then self->setdata, sd_aspect=bulk_data['sd_aspect']
  endif
  
  type='ql_lightcurve'
  if(n_elements(ql_lightcurve) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_light_curves, solo_slices=solo_slices, $
      ql_lightcurve=ql_lightcurve, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif    
  
  type='hc_regular_mini'
  if(n_elements(hc_regular_mini) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_hc_regular_mini, hc_regular_mini=hc_regular_mini, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='hc_regular_maxi'
  if(n_elements(hc_regular_maxi) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_hc_regular_maxi, hc_regular_maxi=hc_regular_maxi, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='hc_heartbeat'
  if(n_elements(hc_heartbeat) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_hc_heartbeat, heartbeat=hc_heartbeat, $
      solo_slices=solo_slices, _extra=extra
    solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='ql_flare_flag_location'
  if(n_elements(ql_flare_flag_location) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_flare_flag_location, ql_flare_flag_location=ql_flare_flag_location, $
    solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='ql_flare_flag'
  if(n_elements(ql_flare_flag) gt 0 or arg_present(ql_flare_location) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_flare_flag_location, ql_flare_flag=ql_flare_flag, $
      ql_flare_location=ql_flare_location, solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif

  type='ql_variance'
  if(n_elements(ql_variance) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_variance, ql_variance=ql_variance, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif

  type='ql_flare_list'
  if(n_elements(ql_flare_list) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_flare_list, ql_flare_list=ql_flare_list, $
      solo_slices=solo_slices, _extra=extra
    solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='ql_spectra'
  if(n_elements(ql_spectra) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_spectra, ql_spectra=ql_spectra, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
 
  type='ql_background_monitor'
  if(n_elements(ql_background_monitor) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_background_monitor, ql_background_monitor=ql_background_monitor, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
 
  type='ql_calibration_spectrum'
  if(n_elements(ql_calibration_spectrum) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_ql_calibration_spectrum, ql_calibration_spectrum=ql_calibration_spectrum, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='sd_xray_0'
  if(n_elements(sd_xray_0) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_sd_xray_0, L0_ARCHIVE_BUFFER_GROUPED=sd_xray_0, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif

  type='sd_xray_1'
  if(n_elements(sd_xray_1) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_sd_xray_1, L1_IMG_COMBINED_ARCHIVE_BUFFER_GROUPED=sd_xray_1, $
      solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
      self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif

  type='sd_xray_2'
  if(n_elements(sd_xray_2) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_sd_xray_1, L2_IMG_COMBINED_PIXEL_SUMS_GROUPED=sd_xray_2, $
      solo_slices=solo_slices, /lvl_2, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='sd_xray_3'
  if(n_elements(sd_xray_3) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_sd_xray_3, L3_IMG_COMBINED_VISIBILITY_GROUPED=sd_xray_3, $
      solo_slices=solo_slices, _extra=extra
    solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='sd_spc'
  if(n_elements(sd_spc) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_sd_spectrogram, L1_SPC_COMBINED_ARCHIVE_BUFFER_GROUPED=sd_spc, $
     solo_slices=solo_slices, _extra=extra
      solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  type='sd_aspect'
  if(n_elements(sd_aspect) gt 0) then begin
    solo_slices = []
    stx_telemetry_prepare_structure_sd_aspect, aspect=sd_aspect, solo_slices=solo_slices, _extra=extra
    
    solo_slices[*].coarse_time+=((indgen(n_elements(solo_slices))+1)+self.obt_counter)
    self.obt_counter+=n_elements(solo_slices)
    self->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_slices
    self->add_solo_slices, solo_slices=solo_slices, type=type
  endif
  
  if(n_elements(solo_packets) gt 0) then solo_packets=self.solo_packets
  
end


pro stx_telemetry_writer::add_solo_slices, solo_slices=solo_slices, type=type
    if (not self.solo_packets.haskey(type)) then (self.solo_packets)[type] = list()
    (self.solo_packets)[type].add, solo_slices
end


pro stx_telemetry_writer::write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_source_packet_header_structure, _extra=extra

  ppl_require, in=solo_source_packet_header_structure, type='stx_tmtc_solo_source_packet_header*'

  foreach solo_pkg, solo_source_packet_header_structure do begin

    tags = strlowcase(tag_names(solo_pkg))

    for tag_idx = 0L, n_tags(solo_pkg)-1 do begin
      tag = tags[tag_idx]

      if(tag eq 'type' || stregex(tag, 'pkg_.*', /bool)) then continue

      tag_len = solo_pkg.pkg_word_width.(tag_index(solo_pkg.pkg_word_width, tag))
      tag_val = solo_pkg.(tag_idx)

      if(tag eq 'source_data') then begin
        if((size(*tag_val))[2] eq 11) then source_data_type = (*tag_val)[0].type else $
          source_data_type = (*tag_val).type
        switch (source_data_type) of
          'stx_tmtc_ql_calibration_spectrum': begin
            stx_telemetry_write_ql_calibration_spectrum, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_sd_aspect': begin
            stx_telemetry_write_sd_aspect, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_ql_light_curves': begin
            stx_telemetry_write_ql_light_curves, tmw=self, *tag_val, _extra=extra
            break
          end   
          'stx_tmtc_ql_spectra': begin
            stx_telemetry_write_ql_spectra, tmw=self, *tag_val, _extra=extra
            break
          end       
          'stx_tmtc_ql_variance': begin
            stx_telemetry_write_ql_variance, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_ql_flare_list': begin
            stx_telemetry_write_ql_flare_list, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_ql_background_monitor': begin
            stx_telemetry_write_ql_background_monitor, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_ql_flare_flag_location': begin
            stx_telemetry_write_ql_flare_flag_location, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_hc_heartbeat': begin
            stx_telemetry_write_hc_heartbeat, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_hc_regular_mini': begin
            stx_telemetry_write_hc_regular_mini, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_hc_regular_maxi': begin
            stx_telemetry_write_hc_regular_maxi, tmw=self, *tag_val, _extra=extra
            break
          end
          'stx_tmtc_sd_xray': begin
            ; write static fields
            stx_telemerty_util_write_header, packet=(*tag_val), tmw=self
            
            ; write either level 0,1,2 or 3
            sub_type = (*(*tag_val).dynamic_subheaders)[0].type
            switch (sub_type) of
              'stx_tmtc_sd_xray_0': begin
                stx_telemetry_write_sd_xray_0, tmw=self, (*(*tag_val).dynamic_subheaders), _extra=extra
                break
              end
              'stx_tmtc_sd_xray_1': begin
                stx_telemetry_write_sd_xray_1, tmw=self, (*(*tag_val).dynamic_subheaders), _extra=extra
                break
              end
              'stx_tmtc_sd_xray_3': begin
                stx_telemetry_write_sd_xray_3, tmw=self, (*(*tag_val).dynamic_subheaders), _extra=extra
                break
              end
              'stx_tmtc_sd_spectrogram': begin
                stx_telemetry_write_sd_spectrogram, tmw=self, (*(*tag_val).dynamic_subheaders), _extra=extra
                break
              end
            endswitch
            

            break
          end
          else: begin
             message, 'Unknown STIX telemetry packet type.'
          end
        endswitch
      endif else begin
        ;add 1 second to obt_time in order to be compliant with monotonie checks
;        if(tag eq 'coarse_time') then begin
;          self.obt_counter+=1
;          tag_val+=self.obt_counter
;          solo_pkg.coarse_time+=self.obt_counter
;        endif
        ; regular header tag
        self->write, tag_val, bits=tag_len, debug=debug, silent=silent
      endelse
    endfor

    self->setBoundary

  endforeach

end



pro stx_telemetry_writer::finalize_science_package_header, positions, nsamples, $
  silent = silent, $
  debug = debug

  default, debug, 0
  default, silent, ~debug

  datalength = self.byteptr + self.bitptr lt 8 ? 1 : 0

  ;Packet data field length - 1
  self->write, datalength, bits=32, debug=debug, silent=silent, tmp_write_pos=positions.length_position


  ;Number of samples (N)
  self->write, nsamples, bits=16, debug=debug, silent=silent, tmp_write_pos=positions.samples_position


end

function stx_telemetry_writer::science_package_header, $
  ssid = ssid, $
  time = time, $
  auxiliary_hk_data = auxiliary_hk_data, $
  silent = silent, $
  debug = debug

  default, debug, 0
  default, silent, ~debug

  default, ssid, 0b
  default, auxiliary_hk_data, bytarr(6)
  default, time, stx_time()



  ; write data to headar
  if(debug) then self->debug_message, 'SCIENCE PACKAGE HEADER'

  ;APID – PID
  self->write, 91b, bits=8, debug=debug, silent=silent

  ;APID – Packet Category
  self->write, 12b, bits=8, debug=debug, silent=silent

  ;Packet data field length - 1
  self->write, 0, bits=32, debug=debug, silent=silent,BEFORE_PTR=length_position

  ;Service Type
  self->write, 21b, bits=8, debug=debug, silent=silent

  ;Service Subtype
  self->write, 3b, bits=8, debug=debug, silent=silent

  ;Science Structure ID (SSID)
  self->write, ssid, bits=8, debug=debug, silent=silent

  ;Auxiliary HK data
  self->write, auxiliary_hk_data, bits=8, debug=debug, silent=silent, /EXTRACT

  ;Measurement Time Stamp
  self->write,  stx_time2scet(time), bits=32, debug=debug, silent=silent, /extract

  ;Number of samples (N)
  self->write, 0, bits=16, debug=debug, silent=silent, BEFORE_PTR=samples_position

  if(debug) then self->debug_message, 'SCIENCE PACKAGE HEADER', state='-'

  return, {length_position : length_position, samples_position : samples_position}

end


;+
; :description:
;    This routine adds the sub-header science data to the telemetry stream.
;    This initial version uses default values (0) for many of the data fields. It
;    is not optimized for time or memory.
;
; :categories:
;    simulation, writer, telemetry
;
; :params:
;    pixel_data : in, required, type="stx_pixel_data"
;             The pixel data input contains simulated pixel data over
;             one time and energy, or multiple times and energies
;
; :keywords:
;    ssid : in, required, type="int"
;          This is the service id for this sub-header science data. One of 10, 11, 12, 13
;
;    time : in, optional, type="long or longarr()", default="lindgen(n_elements(pixel_data.taxis))"
;           This keyword specifies which time (index!) from pixel data should be used
;           and converted to the archive buffer format. If an array of indices
;           is passed in, all archive buffers are returned as one and the keyword
;           archidx contains the indices of the archive buffer entry points by time.
;
;    no_bits : out, optional, type="long"
;              This keyword returns the size of this packet in bits
;
;    silent : in, optional, type="boolean", default="1"
;             If set this routine will not print out any verbose information
;
;    debug : in, optional, type="boolean", default="0"
;            If set this routine will print debugging information (packet sizes, etc.)
;
; :examples:
;    stx_sim_demo, pxl_data=pixel_data
;    tmw = stx_telemetry_writer()
;    tmw->shsd, pixel_data, ssid=10
;
; :history:
;    26-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), added debug keyword and statements
;    03-Apr-2013 - Laszlo I. Etesi (FHNW), added bit counter (packet size)
;    20-Apr-2013 - Nicky Hochmuth (FHNW), integrate to object
;    12-Sep-2013 - Nicky Hochmuth (FHNW), rewriten
;    11-feb-2015 - RAS, fixed SUMED to SUMMED
;
;-
pro stx_telemetry_writer::science_header_science_data, data, ssid, $
  delta_time = delta_time, $
  rc_regime = rc_regime, $
  pixel_mask = pixel_mask, $
  cfl = cfl, $
  detector_mask = detector_mask, $
  livetime = livetime, $
  no_bits = no_bits, $
  silent = silent, $
  debug = debug
  ; set default values
  default, debug, 0
  default, silent, ~debug

  default, delta_time, 0d
  default, rc_regime, 0b
  default, pixel_mask, bytarr(12)+1
  default, detector_mask, bytarr(32)+1
  default, cfl, [0,0]
  default, livetime, uintarr(16)

  ; keep a bit counter, compare with bit count at the end
  bitctr = self->getbitposition()

  ; delta time
  delta_time_s = fix(delta_time)
  delta_time_ms = fix((delta_time-delta_time_s) * 1000)

  if(delta_time_s ge 2L^16) then message, "Delta Time Seconds does not fit in 16 bits"

  if(rc_regime ge 16) then message, "rate controle regime does not fit in 4 bits"

  pixel_mask_bits = stx_mask2bits(pixel_mask)
  if(pixel_mask_bits ge 2^12) then message, "bit mask does not fit in 12 bits"

  detector_mask_bits = stx_mask2bits(detector_mask)
  if(detector_mask_bits gt (2UL^32)-1) then message, "detector mask does not fit in 32 bits"

  ;TODO: n.h. livetime compression
  if ~array_equal(livetime, uint(livetime)) then message, "live time values does not fit in 16 bits per entry", /continue

  ;TODO: n.h. transform cfl correct
  cfl_x = uint(cfl[0])
  cfl_y = uint(cfl[1])
  if(cfl_x ge 256) then message, "cfl_x does not fit in 8 bits"
  if(cfl_x ge 256) then message, "cfl_y does not fit in 8 bits"

  no_sub_structures = 0u
  bits_for_no_sub_structures = 16
  switch (ssid) of
    !STX_TM_SID.sd_archive_buffer: begin
      ppl_require, in=data, type='stx_fsw_archive_buffer*'
      data_stream = stx_archive_struct_to_telemetry_buffer(data, nrowt = no_sub_structures)
      bits_for_no_sub_structures = 16
      break
    end
    !STX_TM_SID.sd_pixels: begin
      ppl_require, in=data, type='stx_fsw_pixel_data*'
      data_stream = stx_ivs_images_level_one_to_telemetry_buffer(data)
      bits_for_no_sub_structures = 16
      break
    end
    !STX_TM_SID.sd_summedpixels: begin
      ppl_require, in=data, type='stx_fsw_pixel_data_summed*'
      data_stream = stx_ivs_images_level_two_to_telemetry_buffer(data)
      bits_for_no_sub_structures = 16
      break
    end
    !STX_TM_SID.sd_viesibilities: begin
      message, 'Not implemented yet. Returning...', /continue, /informational
      return
      break
    end
    else: begin
      message, 'Unrecognized science data sample type.'
    end
  endswitch

  no_sub_structures = ulong(no_sub_structures)

  ; write data to headar
  if(debug) then self->debug_message, 'SCIENCE HEADER'

  self->write, delta_time_s, bits=16, debug=debug, silent=silent
  self->write, delta_time_ms, bits=10, debug=debug, silent=silent
  self->write, rc_regime, bits=4, debug=debug, silent=silent
  self->write, no_sub_structures, bits=bits_for_no_sub_structures, debug=debug, silent=silent
  self->write, pixel_mask_bits, bits=12, debug=debug, silent=silent
  ;spare
  self->write, 0b, bits=6, debug=debug, silent=silent
  self->write, detector_mask_bits, bits=32, debug=debug, silent=silent
  self->write, cfl_x, bits=8, debug=debug, silent=silent
  self->write, cfl_y, bits=8, debug=debug, silent=silent


  self->write,  livetime, bits=16, debug=debug, silent=silent, /extract


  if(debug) then self->debug_message, 'SCIENCE HEADER', state='-'

  if(debug) then self->debug_message, 'SCIENCE DATA'

  self->write,  data_stream, bits=8, debug=debug, silent=silent, /extract

  if(debug) then self->debug_message, 'SCIENCE DATA', state='-'

  no_bits = self->getbitposition() - bitctr
end



;+
; :description:
;    This routine adds the source data to the telemetry stream.
;    This initial version uses default values (0) for many of the data fields. It
;    is not optimized for time or memory.
;
; :categories:
;    simulation, writer, telemetry
;
; :params:
;    pixel_data : in, required, type="stx_pixel_data"
;             The pixel data input contains simulated pixel data over
;             one time and energy, or multiple times and energies
;
; :keywords:
;    ssid : in, required, type="int"
;          This is the service id for this sub-header science data. One of 10, 11, 12, 13
;
;    time : in, optional, type="long or longarr()", default="lindgen(n_elements(pixel_data.taxis))"
;           This keyword specifies which time (index!) from pixel data should be used
;           and converted to the archive buffer format. If an array of indices
;           is passed in, all archive buffers are returned as one and the keyword
;           archidx contains the indices of the archive buffer entry points by time.
;
;    no_bits : out, optional, type="long"
;              This keyword returns the size of this packet in bits
;
;    silent : in, optional, type="boolean", default="1"
;             If set this routine will not print out any verbose information
;
;    debug : in, optional, type="boolean", default="0"
;            If set this routine will print debugging information (packet sizes, etc.)
;
; :examples:
;    stx_sim_demo, pxl_data=pixel_data
;    tmw = stx_telemetry_writer()
;    tmw->sd, pixel_data, ssid=10
;
; :history:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    03-Apr-2013 - Laszlo I. Etesi (FHNW), added bit counter (packet size)
;    20-Apr-2013 - Nicky Hochmuth (FHNW), integrate to object
;
; :todo:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), replace placeholder values with real values
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), verify which values require keyword input option
;-
pro stx_telemetry_writer::sd, pixel_data, ssid=ssid, time=time, no_bits=no_bits, debug=debug, silent=silent
  ; set default values
  default, debug, 0
  default, silent, ~debug

  default, time, lindgen(n_elements(pixel_data.taxis))

  ; keep a bit counter, compare with bit count at the end
  bitctr = self->getbitposition()

  ; ***************************
  ; prepare debug information
  ; ***************************
  if(debug) then begin
    self->debug_message, 'SOURCE DATA'
  endif

  ; ****************
  ; Build HK data
  ; ****************

  ; get invalid detector mask (32 bits)
  idm = 0L

  ; reserved (1 bit)
  aux_reserved_1 = 0

  ; get instrument model id (3 bits), set to SIM (111 base 2)
  imid = 3^2-1

  ; get rate control regime (4 bits)
  rc_regime = 0L

  ; get attenuator failure flag (1 bit), set to OK (1 base 2)
  aff = 0

  ; get high voltage failure flat (1 bit), set to OK (1 base 2)
  hvf = 0

  ; reserved (6 bits)
  aux_reserved_2 = 0

  ; ****************

  ; get measured time stamp (??? bits)
  scet_tstamp = 0

  ; get number of samples (16 bits)
  no_samples = n_elements(time)

  ; write aux data, time stamp, and no_samples to stream
  self->write, data=idm, bits=32, debug=debug, silent=silent
  self->write, data=aux_reserved_1, bits=1, debug=debug, silent=silent
  self->write, data=imid, bits=3, debug=debug, silent=silent
  self->write, data=rc_regime, bits=4, debug=debug, silent=silent
  self->write, data=aff, bits=1, debug=debug, silent=silent
  self->write, data=hvf, bits=1, debug=debug, silent=silent
  self->write, data=aux_reserved_2, bits=6, debug=debug, silent=silent
  ; self->write, data=scet_tstamp, bits=???, debug=debug, silent=silent
  self->write, data=no_samples, bits=16, debug=debug, silent=silent

  ; ***************************
  ; prepare debug information
  ; ***************************
  if(debug) then begin
    self->debug_message, 'SOURCE DATA', bitctr=bitctr, state='-'
  endif

  for time_i = 0L, no_samples-1 do begin
    ; for each time interval in pixel_data, attach a sub-header science data packet
    self->shsd, pixel_data, ssid=ssid, time=time_i, debug=debug, silent=silent, debug=debug, silent=silent
  endfor

  ; ***************************
  ; prepare debug information
  ; ***************************
  ; calculate delta bits
  if(debug) then self->debug_message, 'SOURCE DATA', bitctr=bitctr

  ; calculate the packet size
  no_bits = self->getbitposition() - bitctr
end


;+
; :description:
;    This routine adds the source data to the telemetry stream.
;    This initial version uses default values (0) for many of the data fields. It
;    is not optimized for time or memory.
;
; :categories:
;    simulation, writer, telemetry
;
; :params:
;    pixel_data : in, required, type="stx_pixel_data"
;             The pixel data input contains simulated pixel data over
;             one time and energy, or multiple times and energies
;
; :keywords:
;    ssid : in, required, type="int"
;          This is the service id for this sub-header science data. One of 10, 11, 12, 13
;
;    time : in, optional, type="long or longarr()", default="lindgen(n_elements(pixel_data.taxis))"
;           This keyword specifies which time (index!) from pixel data should be used
;           and converted to the archive buffer format. If an array of indices
;           is passed in, all archive buffers are returned as one and the keyword
;           archidx contains the indices of the archive buffer entry points by time.
;
;    no_bits : out, optional, type="long"
;              This keyword returns the size of this packet in bits
;
;    silent : in, optional, type="boolean", default="1"
;             If set this routine will not print out any verbose information
;
;    debug : in, optional, type="boolean", default="0"
;            If set this routine will print debugging information (packet sizes, etc.)
;
; :examples:
;    stx_sim_demo, pxl_data=pixel_data
;    tmw = stx_telemetry_writer()
;    tmw->pd, pixel_data, ssid=10
;
; :history:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    20-Apr-2013 - Nicky Hochmuth (FHNW), integrate to object
;
; :todo:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), replace placeholder values with real values
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), verify which values require keyword input option
;-
pro stx_telemetry_writer::pd, pixel_data, ssid=ssid, time=time, no_bits=no_bits, debug=debug, silent=silent
  ; set default values
  default, debug, 0
  default, silent, ~debug
  default, time, lindgen(n_elements(pixel_data.taxis))

  ; keep a bit counter, compare with bit count at the end
  bitctr = self->getbitposition()

  ; ***************************
  ; prepare debug information
  ; ***************************
  if(debug) then begin
    self->debug_message, 'PACKET DATA'
  endif

  ; get first spare bit (1 bit)
  spare_1 = 0b

  ; get PUS version number (3 bits)
  pus = 1b

  ; get second spare bit (4 bits)
  spare_2 = 0b

  ; get service type (8 bits)
  stype = 21

  ; get service sub type (8 bits)
  ssubtype = 3

  ; get synch status (8 bits)
  synch = 0

  ; get absolute time (48 bits)
  abstime = 0L

  ; write data
  self->write, data=spare_1, bits=1, debug=debug, silent=silent
  self->write, data=pus, bits=3, debug=debug, silent=silent
  self->write, data=spare_2, bits=4, debug=debug, silent=silent
  self->write, data=stype, bits=8, debug=debug, silent=silent
  self->write, data=ssubtype, bits=8, debug=debug, silent=silent
  self->write, data=synch, bits=8, debug=debug, silent=silent
  self->write, data=abstime, bits=48, debug=debug, silent=silent

  ; ***************************
  ; prepare debug information
  ; ***************************
  ; calculate delta bits
  if(debug) then self->debug_message, 'PACKET DATA', bitctr=bitctr, state="-"

  self->sd, pixel_data, ssid=ssid, time=time, debug=debug, silent=silent, debug=debug, silent=silent

  ; ***************************
  ; prepare debug information
  ; ***************************
  ; calculate delta bits
  if(debug) then self->debug_message, 'PACKET DATA', bitctr=bitctr

  ; calculate the packet size
  no_bits = self->getbitposition() - bitctr
end

;+
; :description:
;    This routine adds the source packet header to the telemetry stream.
;    This initial version uses default values (0) for many of the data fields. It
;    is not optimized for time or memory.
;
; :categories:
;    simulation, writer, telemetry
;
; :params:
;    pixel_data : in, required, type="stx_pixel_data"
;             The pixel data input contains simulated pixel data over
;             one time and energy, or multiple times and energies
;
; :keywords:
;    ssid : in, required, type="int"
;          This is the service id for this sub-header science data. One of 10, 11, 12, 13
;
;    time : in, optional, type="long or longarr()", default="lindgen(n_elements(pixel_data.taxis))"
;           This keyword specifies which time (index!) from pixel data should be used
;           and converted to the archive buffer format. If an array of indices
;           is passed in, all archive buffers are returned as one and the keyword
;           archidx contains the indices of the archive buffer entry points by time.
;
;    packet_length_tmw_pointer : out, optional, type="lonarr(2)"
;           This keyword returns the byte and bit position pointer into the telemetry
;           stream so that the packet length can be edited when it is known (depends
;           on source data packet)
;
;    no_bits : out, optional, type="long"
;              This keyword returns the size of this packet in bits
;
;    silent : in, optional, type="boolean", default="1"
;             If set this routine will not print out any verbose information
;
;    debug : in, optional, type="boolean", default="0"
;            If set this routine will print debugging information (packet sizes, etc.)
;
; :examples:
;    stx_sim_demo, pxl_data=pixel_data
;    tmw = stx_telemetry_writer()
;    tmw->sph, pixel_data, ssid=10
;
; :history:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), initial release
;    20-Apr-2013 - Nicky Hochmuth (FHNW), integrate to object
;
; :todo:
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), replace placeholder values with real values
;    27-Mar-2013 - Laszlo I. Etesi (FHNW), verify which values require keyword input option
;-
pro stx_telemetry_w_sph, pixel_data, ssid=ssid, time=time, packet_length_tmw_pointer=packet_length_tmw_pointer, no_bits=no_bits,debug=debug, silent=silent
  ; set default values
  default, debug, 0
  default, silent, ~debug
  default, time, lindgen(n_elements(pixel_data.taxis))

  ; keep a bit counter, compare with bit count at the end
  bitctr = self->getbitposition()

  ; ***************************
  ; prepare debug information
  ; ***************************
  if(debug) then begin
    self->debug_message, 'SOURCE PACKET HEADER'
  endif

  ; ***********
  ; Packet ID
  ; ***********

  ; get version number (3 bits)
  version = 0

  ; get type (1 bit)
  type = 0

  ; get data field header flag, fixed to 1b (1 bit)
  dfhf = 1b

  ; get application pid - process id (7 bits)
  apid_pi = 0

  ; get application pid - packet category (4 bits)
  apid_pc = 0

  ; *************************
  ; Packet Sequence Control
  ; *************************

  ; get segmentation and grouping flags (2 bits)
  sgf = 0

  ; get source sequence count (14 bits)
  ssc = 0

  ; packet length is not yet known, will
  ; be inserted at the end (16 bits)
  packet_length = 0

  ; write data
  self->write , data=version, bits=3, debug=debug, silent=silent
  self->write , data=type, bits=1, debug=debug, silent=silent
  self->write , data=dfhf, bits=1, debug=debug, silent=silent
  self->write , data=apid_pi, bits=7, debug=debug, silent=silent
  self->write , data=apid_pc, bits=4, debug=debug, silent=silent
  self->write , data=sgf, bits=2, debug=debug, silent=silent
  self->write , data=ssc, bits=14, debug=debug, silent=silent
  self->write , data=packet_length, bits=16, before_ptr=packet_length_tmw_pointer, debug=debug, silent=silent

  ; ***************************
  ; prepare debug information
  ; ***************************
  if(debug) then begin
    self->debug_message, 'SOURCE PACKET HEADER', bitctr=bitctr
  endif

  ; calculate the packet size
  no_bits = self->getbitposition() - bitctr
end

pro stx_telemetry_writer__define
  compile_opt idl2, hidden

  ; create stx_telemetry_writer structure that contains all information
  ; for the tm data reading process
  void = { stx_telemetry_writer, $
    inherits stx_bitstream_writer,$
    obt_counter: 0L, $
    solo_packets : HASH() }
end