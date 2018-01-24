;+
; :description:
;   this routine generates the flare_flag_location quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    34
;   > Coarse Time (SCET)                    -                   4 octets
;   > Fine Time (SCET)                      -                   2 octets
;   > Delta Time                            -                   1 octet
;   > Number of Samples (N)                 -                   2 octet
;   > Flare
;   > > flare_flag                                              1 octet             per spectra (1xN)
;   > > flare_location_z                                        1 octet             per spectra (1xN)
;   > > flare_location_z                                        1 octet             per spectra (1xN)
;
; :categories:
;   simulation, writer, telemetry, quicklook, flare_flag_location
;
; :params:
;   flare_flag_location : in, required, type="stx_sim_ql_flare_flag_location"
;     the input flare_flag_location object
;
; :keywords:
;
; :history:
;    27-Jan-2016 - Simon Marcin (FHNW), initial release
;-

function prepare_packet_structure_ql_flare_flag_location_fsw, ql_flare_location=ql_flare_location, $
  ql_flare_flag=ql_flare_flag, _extra=extra

  ; type checking
  ppl_require, in=ql_flare_location, type='stx_fsw_m_coarse_flare_locator'
  ppl_require, in=ql_flare_flag, type='stx_fsw_m_flare_flag'

  ; generate empty flare_flag_location paket
  packet = stx_telemetry_packet_structure_ql_flare_flag_location()

  ; fill in the data
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=ql_flare_location.TIME_AXIS.TIME_START[0], reverse=reverse

  packet.coarse_time = coarse_time
  packet.fine_time = fine_time
  packet.integration_time = ql_flare_location.TIME_AXIS.duration[0]

  ; number of samples
  packet.number_of_samples = n_elements(ql_flare_location.X_POS)
  
  ; if flare_flag has another duration than location we skip flags in between
  skip_factor = fix(n_elements(ql_flare_flag.FLARE_FLAG) / n_elements(ql_flare_location.X_POS))

  ; initialize pointer and prepare arrays for flare details
  packet.dynamic_flare_flag = ptr_new(bytarr(packet.number_of_samples))
  packet.dynamic_flare_location_z = ptr_new(bytarr(packet.number_of_samples))
  packet.dynamic_flare_location_y = ptr_new(bytarr(packet.number_of_samples))

  ;Loop through all data samples
  for sample_id = 0L, packet.number_of_samples-1 do begin

    ; get flare_flag value
    sub_flare_flag = ql_flare_flag.flare_flag[sample_id*skip_factor]

    ; get flare_location_z
    sub_flare_location_z = ql_flare_location.X_POS[sample_id]
    sub_flare_location_y = ql_flare_location.Y_POS[sample_id]

    ; attach subs to packet
    (*packet.dynamic_flare_flag)[sample_id] = reform(sub_flare_flag)
    (*packet.dynamic_flare_location_z)[sample_id] = reform(sub_flare_location_z)
    (*packet.dynamic_flare_location_y)[sample_id] = reform(sub_flare_location_y)

  endfor

  return, packet
end


pro stx_telemetry_prepare_structure_ql_flare_flag_location_write, solo_slices=solo_slices, $
  ql_flare_location=ql_flare_location, ql_flare_flag=ql_flare_flag, $
  _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate spectra intermediate TM packet
  if(arg_present(ql_flare_flag_location)) then begin
    ;source_data = prepare_packet_structure_ql_flare_flag_location_asw($
      ;ql_flare_flag_location=ql_flare_flag_location, _extra=extra)
  endif 
  if(arg_present(ql_flare_flag) or arg_present(ql_flare_location)) then begin
    source_data = prepare_packet_structure_ql_flare_flag_location_fsw( $
      ql_flare_location=ql_flare_location, ql_flare_flag=ql_flare_flag, _extra=extra)
  endif
  
  ; set the sc time of the solo_header packet
  solo_source_packet_header.coarse_time = source_data.coarse_time
  solo_source_packet_header.fine_time = source_data.fine_time
  
  ; copy all header information to solo packet
  ; TODO: Refactor to util function
  tags = strlowcase(tag_names(source_data))

  for tag_idx = 0L, n_tags(source_data)-1 do begin
    tag = tags[tag_idx]

    if(~stregex(tag, 'header_.*', /bool)) then continue

    ; Copy the matching header information to solo_source_packet_header
    tag_val = source_data.(tag_idx)
    solo_source_packet_header.(tag_index(solo_source_packet_header, (stregex(tag, 'header_(.*)', /extract, /subexpr))[1])) = tag_val
  endfor

  ; get the number of data samples
  n_samples = source_data.number_of_samples

  ; size of dynamic part
  dynamic_struct_size = 1+1+1

  ; max fitting flare_details per paket
  max_fitting_paket = UINT((max_packet_size - source_data.pkg_word_width.pkg_total_bytes_fixed)/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size

  ;Process ever sample with its trigger acumulator, detector index and delta_time
  for sample_idx = 0L, n_samples-1 do begin

    ; check if we have an overflow; if so -> start a new packet
    if(curr_packet_size + dynamic_struct_size gt max_packet_size) then begin
      ; copy the 'SolO' packet
      solo_slice = solo_source_packet_header

      ; add 'SolO' slice to 'SolO' array
      if(isvalid(solo_slices)) then solo_slices = [solo_slices, solo_slice] $
      else solo_slices = solo_slice

      ; set the sequence count
      solo_slices[-1].source_sequence_count = n_elements(solo_slices) - 1

      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length = 9

      ; initialize the current packet size to the fixed packet length
      curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed * 8
    endif

    ; run the following lines of code if we started a new 'SolO' packet
    if(solo_slices[-1].source_data eq ptr_new()) then begin
      ; copy the source data (prepare this 'partial' packet); copy it so that the fields are pre-initialized
      partial_source_data = ptr_new(source_data)

      ; add general pakete information to 'SolO' slice
      solo_slices[-1].source_data = partial_source_data

      ; calculate the amount of fitting pakets
      if((n_samples-sample_idx)*dynamic_struct_size gt max_packet_size-curr_packet_size) then begin
        ; use all available space 
        fitting_pakets = max_fitting_paket
      endif else begin
        ; just use the needed space for the last few pakets
        fitting_pakets = n_samples-sample_idx
      endelse

      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_flare_flag = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_flare_location_z = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_flare_location_y = ptr_new(bytarr(fitting_pakets)-1)

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).number_of_samples = 0

      ; update all packet data field lengths
      solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
      solo_slices[-1].data_field_length += (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length

      ; Set the dynamic lenght to 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_flare_flag = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_flare_location_z = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_flare_location_y = 0
    endif

    ; run the following lines of code when adding a new flare details to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_flare_flag)[(sample_idx MOD max_fitting_paket)] eq -1) then begin
      ; copy the slices to new pointers
      flare_flag_slice = reform((*source_data.dynamic_flare_flag)[sample_idx])
      flare_location_z_slice = reform((*source_data.dynamic_flare_location_z)[sample_idx])
      flare_location_y_slice = reform((*source_data.dynamic_flare_location_y)[sample_idx])

      ; attach slices to paket
      (*(*solo_slices[-1].source_data).dynamic_flare_flag)[(sample_idx MOD max_fitting_paket)] = flare_flag_slice
      (*(*solo_slices[-1].source_data).dynamic_flare_location_z)[(sample_idx MOD max_fitting_paket)] = flare_location_z_slice
      (*(*solo_slices[-1].source_data).dynamic_flare_location_y)[(sample_idx MOD max_fitting_paket)] = flare_location_y_slice

      ; adjust current packet size
      curr_packet_size += dynamic_struct_size
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size * 8
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size
      solo_slices[-1].data_field_length += dynamic_struct_size

      ; adjust number of attached structures
      (*solo_slices[-1].source_data).number_of_samples++

    endif
  endfor
  
  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end


pro stx_telemetry_prepare_structure_ql_flare_flag_location_read, solo_slices=solo_slices, $
  asw_ql_flare_flag_location=asw_ql_flare_flag_location, $
  fsw_m_coarse_flare_locator=fsw_m_coarse_flare_locator, $
  fsw_m_flare_flag=fsw_m_flare_flag, _extra=extra

  ; init counter for number of structures
  total_number_of_structures=0

  ; read all solo_slices
  for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin
    
    ; count nbr_of_data_samples
    total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_of_samples
    
    ;get slices
    slice_flag = byte((*(*solo_slices[solo_slice_idx].source_data).dynamic_flare_flag))
    slice_x_pos = fix((*(*solo_slices[solo_slice_idx].source_data).dynamic_flare_location_z))
    slice_y_pos = fix((*(*solo_slices[solo_slice_idx].source_data).dynamic_flare_location_y))
    
    ; append the slices to the final arrays
    if  solo_slice_idx eq 0 then begin
      flag = slice_flag
      x_pos = slice_x_pos
      y_pos = slice_y_pos
    endif else begin
      flag = [flag, slice_flag]
      x_pos = [x_pos, slice_x_pos]
      y_pos = [y_pos, slice_y_pos]
    endelse
        
  endfor
   
  ; create time_axis
  stx_telemetry_util_time2scet,coarse_time=(*solo_slices[0].source_data).coarse_time, $
    fine_time=(*solo_slices[0].source_data).fine_time, stx_time_obj=t0, /reverse
  seconds=lindgen(total_number_of_structures+1)* ((*solo_slices[0].source_data).integration_time / 10.)
  axis=stx_time_add(t0,seconds=seconds)
  time_axis=stx_construct_time_axis(axis)
  
  ; create new stx_asw_ql_flare_flag_location object
  if(arg_present(asw_ql_flare_flag_location)) then begin
    asw_ql_flare_flag_location=stx_asw_ql_flare_flag_location(total_number_of_structures)
    asw_ql_flare_flag_location.time_axis = time_axis
    asw_ql_flare_flag_location.flare_flag = flag
    asw_ql_flare_flag_location.X_POS = x_pos
    asw_ql_flare_flag_location.Y_POS = y_pos
  endif
  
  ; create fsw_structures
  if(arg_present(fsw_m_coarse_flare_locator) or arg_present(fsw_m_flare_flag)) then begin
    fsw_m_coarse_flare_locator=stx_fsw_m_coarse_flare_locator(x_pos=x_pos, $
      y_pos=y_pos, time_axis=time_axis )
    fsw_m_flare_flag=stx_fsw_m_flare_flag( flare_flag=flag, time_axis=time_axis)
  endif
  
end


pro stx_telemetry_prepare_structure_ql_flare_flag_location, solo_slices=solo_slices, $
  ql_flare_location=ql_flare_location, ql_flare_flag=ql_flare_flag, $
  asw_ql_flare_flag_location=asw_ql_flare_flag_location, $
  fsw_m_coarse_flare_locator=fsw_m_coarse_flare_locator, $
  fsw_m_flare_flag=fsw_m_flare_flag, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_flare_flag_location_write, solo_slices=solo_slices, $
      ql_flare_location=ql_flare_location, ql_flare_flag=ql_flare_flag, $
      _extra=extra

  ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_flare_flag_location_read, solo_slices=solo_slices, $
      asw_ql_flare_flag_location=asw_ql_flare_flag_location, $
      fsw_m_coarse_flare_locator=fsw_m_coarse_flare_locator, $
      fsw_m_flare_flag=fsw_m_flare_flag, _extra=extra
  endelse

end

