;+
; :description:
;   this routine generates the light curves quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    30
;   > Coarse Time (SCET)                    -                   4 octets
;   > Fine Time (SCET)                      -                   2 octets
;   > Integration Time                      -                   1 octet
;   > Detector Mask                         -                   4 octets
;   > Pixel Mask                            -                   12 bits
;   > Energy Bin Mask                       -                   33 bits             --> E Masks
;   > Spare block                           -                   3 bits
;   > Compression Schema Light Curves       -                   1 octet
;   > Compression Schema Trigger            -                   1 octet
;   > Number of Structures (N)              -                   2 octet
;   > Light Curves
;   > > Lightcurves                                             E octets            per light curve (ExN)
;   > > Trigger Accumulator                                     1 octet             per light curve (1xN)
;   > > RCR value                                               1 octet             per light curve (1xN)
;
; :categories:
;   simulation, writer, telemetry, quicklook, light curves
;
; :params:
;   light_curves : in, required, type="stx_fsw_ql_lightcurve"
;     the input light curves
;
; :keywords:
;   compression_param_k_lc : in, optional, type='int', default='4'
;     this is the compression parameter k (light_curves), the number of exponent bits to be used
;
;   compression_param_m_lc : in, optional, type='int', default='4'
;     this is the compression parameter m (light_curves), the number of exponent bits to be used
;
;   compression_param_s_lc : in, optional, type='int', default='0'
;     this is the compression parameter s (light_curves), 1 implies the datum may be signed; = 0 if datum is always positive
;
;   compression_param_k_t : in, optional, type='int', default='4'
;     this is the compression parameter k (trigger_accumulator), the number of exponent bits to be used
;
;   compression_param_m_t : in, optional, type='int', default='4'
;     this is the compression parameter m (trigger_accumulator), the number of exponent bits to be used
;
;   compression_param_s_t : in, optional, type='int', default='0'
;     this is the compression parameter s (trigger_accumulator), 1 implies the datum may be signed; = 0 if datum is always positive
;
; :history:
;    13-Nov-2015 - Simon Marcin (FHNW), initial release
;    19-Sep-2016 - Simon Marcin (FHNW), removed pixel mask workaround
;-
function prepare_packet_structure_ql_light_curves_fsw, ql_lightcurve=ql_lightcurve, $
  compression_param_k_lc=compression_param_k_lc, compression_param_m_lc=compression_param_m_lc, $
  compression_param_s_lc=compression_param_s_lc, compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, compression_param_s_t=compression_param_s_t, $
  number_energy_bins=number_energy_bins, _extra=extra

  ; type checking
  ppl_require, in=ql_lightcurve, type='stx_fsw_m_lightcurve'


  default, compression_param_k_t, 5
  default, compression_param_m_t, 3
  default, compression_param_s_t, 0
  default, compression_param_k_lc, 5
  default, compression_param_m_lc, 3
  default, compression_param_s_lc, 0

  ; generate empty light curves paket
  packet = stx_telemetry_packet_structure_ql_light_curves()

  ; fill in the data
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=ql_lightcurve.TIME_AXIS.TIME_START[0]
    
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time
  packet.integration_time = ql_lightcurve.TIME_AXIS.duration[0]*10

  ; s, kkk, mmm for light curves
  packet.compression_schema_light_curves = stx_km_compression_params_to_schema(compression_param_k_lc,compression_param_m_lc,compression_param_s_lc)


  ; s, kkk, mmm for trigger accumulator
  packet.compression_schema_trigger = stx_km_compression_params_to_schema(compression_param_k_t,compression_param_m_t,compression_param_s_t)

  ; the detector, pixel and energy_bin mask are converted to a number
  ; the first entry in the array will become the HSB in the number
  stx_telemetry_util_encode_decode_structure, output=packet, detector_mask=ql_lightcurve.detector_mask, tag='detector_mask'
  stx_telemetry_util_encode_decode_structure, output=packet, pixel_mask=ql_lightcurve.pixel_mask, tag='pixel_mask'
  ; ToDo: Get mask out of lightcurve
  tmp_energy_bin_mask = BYTARR(33)
  tmp_energy_bin_mask[[ql_lightcurve.ENERGY_AXIS.LOW_FSW_IDX]]=1b
  tmp_energy_bin_mask[[32]]=1b
  number_energy_bins=size(ql_lightcurve.ENERGY_AXIS.MEAN, /DIMENSIONS)
  stx_telemetry_util_encode_decode_structure, output=packet, energy_bin_mask=tmp_energy_bin_mask, $
    number_energy_bins=number_energy_bins, tag='energy_bin_mask'
 

  packet.DETECTOR_MASK = ql_lightcurve.DETECTOR_MASK[0]
  packet.PIXEL_MASK = ql_lightcurve.PIXEL_MASK[0]

  ; number of structures (size of second dimension)
  packet.number_of_triggers = (size(ql_lightcurve.ACCUMULATED_COUNTS, /DIM))[1]
  packet.number_of_rcrs = (size(ql_lightcurve.ACCUMULATED_COUNTS, /DIM))[1]
  packet.number_of_energies = number_energy_bins
  ; as it is the same number for each dimension we do not need to make an array here
  packet.dynamic_nbr_of_data_points = (size(ql_lightcurve.ACCUMULATED_COUNTS, /DIM))[1]
  
  ; initialize pointer and prepare arrays for lightcurves, triggers and rcr values
  packet.dynamic_lightcurves = ptr_new(bytarr(number_energy_bins,packet.dynamic_nbr_of_data_points))
  packet.dynamic_trigger_accumulator = ptr_new(bytarr(packet.number_of_triggers))
  packet.dynamic_rcr_values = ptr_new(bytarr(packet.number_of_rcrs))

  ;Loop through all data samples
  for sample_id = 0L, packet.dynamic_nbr_of_data_points-1 do begin

    ; compress lightcurve
    sub_light_curve_compressed = stx_km_compress(ql_lightcurve.ACCUMULATED_COUNTS[*,sample_id], $
      compression_param_k_lc, compression_param_m_lc, compression_param_s_lc)

    ; compress trigger accumulator
    sub_trigger_compressed = stx_km_compress(ql_lightcurve.triggers[sample_id], $
      compression_param_k_lc, compression_param_m_lc, compression_param_s_lc)


    ; attach subs to packet
    (*packet.dynamic_lightcurves)[0:(number_energy_bins-1),sample_id] = reform(sub_light_curve_compressed)
    (*packet.dynamic_trigger_accumulator)[sample_id] = reform(sub_trigger_compressed)
    (*packet.dynamic_rcr_values)[sample_id] = ql_lightcurve.rcr[sample_id]

  endfor

  return, packet
end



pro stx_telemetry_prepare_structure_ql_light_curves_write, solo_slices=solo_slices, ql_lightcurve=ql_lightcurve, $
      _extra=extra
      
  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)
  number_energy_bins = 0
  
  ; generate spectra intermediate TM packet (based on the input type)
  switch (ql_lightcurve.type) of
    'stx_fsw_m_lightcurve': begin
      source_data = prepare_packet_structure_ql_light_curves_fsw(ql_lightcurve=ql_lightcurve, number_energy_bins=number_energy_bins, _extra=extra)
      break
    end
    'stx_asw_ql_lightcurve': begin
      ;source_data = prepare_packet_structure_ql_light_curves_asw(ql_lightcurve=ql_lightcurve, $
      ;  number_energy_bins=number_energy_bins, _extra=extra)
      break
    end
    else: begin
      message, 'Unknown data packet type for ql_light_curves generation: ' + ql_light_curves.type
    end
  endswitch

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

  ; get the number of light_curves
  n_structures = source_data.dynamic_nbr_of_data_points

  ; E octets (light curves/energy binning) + 1 octet trigger + 1 octet rcr values
  dynamic_struct_size = (number_energy_bins + 1 + 1) * 8

  ; max fitting light_curves per paket
  static_packet_size = (source_data.pkg_word_width.pkg_total_bytes_fixed + (number_energy_bins*2))*8
  max_fitting_paket = UINT((max_packet_size - static_packet_size)/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size
  
  ;Process ever light_curve with its trigger acumulator and rcr values
  for structure_idx = 0L, n_structures-1 do begin

    ; check if we have an overflow; if so -> start a new packet
    ; test for E octets (light curves/energy binning) + 1 octet trigger + 1 octet rcr values
    if(curr_packet_size + dynamic_struct_size gt max_packet_size) then begin
      ; copy the 'SolO' packet
      solo_slice = solo_source_packet_header

      ; add 'SolO' slice to 'SolO' array
      if(isvalid(solo_slices)) then solo_slices = [solo_slices, solo_slice] $
      else solo_slices = solo_slice

      ; set the sequence count
      solo_slices[-1].source_sequence_count = n_elements(solo_slices) - 1

      ; initialize the current packet size to the fixed packet length
      curr_packet_size = static_packet_size
    endif

    ; run the following lines of code if we started a new 'SolO' packet
    if(solo_slices[-1].source_data eq ptr_new()) then begin
      ; copy the source data (prepare this 'partial' packet); copy it so that the fields are pre-initialized
      partial_source_data = ptr_new(source_data)

      ; add general pakete information to 'SolO' slice
      solo_slices[-1].source_data = partial_source_data

      ; calculate the amount of fitting pakets
      if((n_structures-structure_idx)*dynamic_struct_size gt max_packet_size-curr_packet_size) then begin
        ; use all available space if more lightcurves than space are available
        fitting_pakets = max_fitting_paket
      endif else begin
        ; just use the needed space for the last few pakets
        fitting_pakets = CEIL(n_structures-structure_idx)
      endelse

      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_lightcurves = ptr_new(bytarr(number_energy_bins,fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_trigger_accumulator = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_rcr_values = ptr_new(bytarr(fitting_pakets)-1)

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).dynamic_nbr_of_data_points = 0
      (*solo_slices[-1].source_data).number_of_triggers = 0
      (*solo_slices[-1].source_data).number_of_rcrs = 0

      ; update all packet data field lengths - TODO: Refactor bytes to bits in name
      solo_slices[-1].pkg_word_width.source_data = static_packet_size
      solo_slices[-1].data_field_length = static_packet_size/8
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length

      ; set the dynamic lenght to 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_lightcurves = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_trigger_accumulator = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_rcr_values = 0
      
      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length += 9

    endif

    ; run the following lines of code when adding a new light_curve to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_lightcurves)[0,(structure_idx MOD max_fitting_paket)] eq -1) then begin
      ; copy the slices to new pointers
      lightcurve_slice = reform((*source_data.dynamic_lightcurves)[0:number_energy_bins-1,structure_idx])
      trigger_slice = reform((*source_data.dynamic_trigger_accumulator)[structure_idx])
      rcr_values_slice = reform((*source_data.dynamic_rcr_values)[structure_idx])

      ; attach slices to paket
      (*(*solo_slices[-1].source_data).dynamic_lightcurves)[0:number_energy_bins-1s,(structure_idx MOD max_fitting_paket)] = lightcurve_slice
      (*(*solo_slices[-1].source_data).dynamic_trigger_accumulator)[(structure_idx MOD max_fitting_paket)] = trigger_slice
      (*(*solo_slices[-1].source_data).dynamic_rcr_values)[(structure_idx MOD max_fitting_paket)] = rcr_values_slice

      ; adjust current packet size
      curr_packet_size += dynamic_struct_size
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size * 8
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size
      solo_slices[-1].data_field_length += dynamic_struct_size/8

      ; increase dynamic lenght
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_lightcurves += number_energy_bins * 8
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_trigger_accumulator += 8
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_rcr_values += 8

      ; adjust number of attached structures
      (*solo_slices[-1].source_data).dynamic_nbr_of_data_points++
      (*solo_slices[-1].source_data).number_of_triggers++
      (*solo_slices[-1].source_data).number_of_rcrs++

    endif
  endfor

  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif 

end



pro stx_telemetry_prepare_structure_ql_light_curves_read, solo_slices=solo_slices, $
  asw_ql_lightcurve=asw_ql_lightcurve,  _extra=extra

  ; convert numbers to masks (only for the first packet)
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).detector_mask, detector_mask=detector_mask
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).energy_bin_mask, $
    energy_bin_mask=energy_bin_mask, number_energy_bins=number_energy_bins

  ; init counter for number of structures
  total_number_of_structures=0
  
  ; get compression params
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_trigger, k=compression_param_k_t, m=compression_param_m_t, s=compression_param_s_t
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_light_curves, k=compression_param_k_lc, m=compression_param_m_lc, s=compression_param_s_lc

  ; get energy axis
  energy_axis=stx_construct_energy_axis(select=(where(energy_bin_mask eq 1)))

  ; reading the solo_sclices and update the STX_ASW_QL_LIGHTCURVE packet
  for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin

    ; count total_number_of_structures
    total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_of_triggers

    ; init slices
    slice_counts = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_lightcurves)),$
      compression_param_k_lc, compression_param_m_lc, compression_param_s_lc)


    slice_triggers = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_trigger_accumulator)),$
      compression_param_k_t, compression_param_m_t, compression_param_s_t)

    slice_rcr = byte((*(*solo_slices[solo_slice_idx].source_data).dynamic_rcr_values))

    ; append the slices to the final arrays
    if  solo_slice_idx eq 0 then begin
      counts = slice_counts
      triggers = slice_triggers
      rate_control_regime = slice_rcr
    endif else begin
      counts = [[counts], [slice_counts]]
      triggers = [triggers, slice_triggers]
      rate_control_regime = [rate_control_regime, slice_rcr]
    endelse

  endfor

  ; create time_axis
  stx_telemetry_util_time2scet,coarse_time=(*solo_slices[0].source_data).coarse_time, $
    fine_time=(*solo_slices[0].source_data).fine_time, stx_time_obj=t0, /reverse
  seconds=lindgen(total_number_of_structures+1)*((*solo_slices[0].source_data).integration_time/10.0)
  axis=stx_time_add(t0,seconds=seconds)
  time_axis=stx_construct_time_axis(axis)

  ;create new stx_asw_ql_lightcurve object
  if(arg_present(asw_ql_lightcurve)) then begin
    asw_ql_lightcurve=stx_construct_asw_ql_lightcurve(time_axis=time_axis, counts=counts, triggers=triggers, $
      rcr=rate_control_regime, detector_mask=detector_mask, energy_axis=energy_axis, pixel_mask=pixel_mask)
  endif
  
end


pro stx_telemetry_prepare_structure_ql_light_curves, solo_slices=solo_slices, ql_lightcurve=ql_lightcurve, $
  asw_ql_lightcurve=asw_ql_lightcurve, _extra=extra
  
  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_light_curves_write, solo_slices=solo_slices, ql_lightcurve=ql_lightcurve, $
      _extra=extra
      
  ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_light_curves_read, solo_slices=solo_slices, $
      asw_ql_lightcurve=asw_ql_lightcurve, _extra=extra
  endelse
end

