;+
; :description:
;   this routine generates the variance quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    33
;   > Coarse Time (SCET)                    -                   4 octets
;   > Fine Time (SCET)                      -                   2 octets
;   > Delta Time                            -                   1 octet
;   > Samples per Variance                  -                   1 octet
;   > Detector Mask                         -                   4 octets
;   > Pixel Mask                            -                   12 bits
;   > NEW Spare                             -                   4 bits              2 Bytes Pixel mask -> 4 spare bits
;   > Compression Schema Accum              -                   1 octet
;   > Energy Channel Lower Bound            -                   5 bits
;   > Energy Channel Upper Bound            -                   5 bits
;   > Spare block                           -                   6 bits
;   > Number of Samples (N)                 -                   2 octet
;   > > Varaince                                                1 octet             per sample (1xN)
;
; :categories:
;   simulation, writer, telemetry, quicklook, variance
;
; :params:
;   variance : in, required, type="stx_sim_ql_variance"
;     the input variance
;
; :keywords:
;   compression_param_k : in, optional, type='int', default='4'
;     this is the compression parameter k (light_curves), the number of exponent bits to be used
;
;   compression_param_m : in, optional, type='int', default='4'
;     this is the compression parameter m (light_curves), the number of exponent bits to be used
;
;   compression_param_s : in, optional, type='int', default='0'
;     this is the compression parameter s (light_curves), 1 implies the datum may be signed; = 0 if datum is always positive
;     
; :history:
;    08-Dec-2015 - Simon Marcin (FHNW), initial release
;-
function prepare_packet_structure_ql_variance_fsw, ql_variance=ql_variance, $
  compression_param_k=compression_param_k, compression_param_m=compression_param_m, $
  compression_param_s=compression_param_s, _extra=extra

  ; type checking
  ppl_require, in=ql_variance, type='stx_fsw_m_variance'

  default, compression_param_k, 5
  default, compression_param_m, 3
  default, compression_param_s, 0
  
  ; generate empty variance paket
  packet = stx_telemetry_packet_structure_ql_variance()

  ; fill in the data
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=ql_variance.TIME_AXIS.TIME_START[0]
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time
  packet.integration_time = fix(ql_variance.time_axis.duration[0]*10) ; *10 as 0.1s in tmtc

  ; s, kkk, mmm for accumulator
  packet.compression_schema_accum = stx_km_compression_params_to_schema($
    compression_param_k,compression_param_m,compression_param_s)

  ; pixel and detector mask already as number
  packet.pixel_mask = ql_variance.pixel_mask[0]
  packet.detector_mask = ql_variance.detector_mask[0]
  energy_mask = bytarr(32)
  energy_mask[fix(ql_variance.energy_axis.low[0]) : fix(ql_variance.energy_axis.high[0])] = 1
  packet.energy_mask = stx_mask2bits(packet.energy_mask)
  ;packet.energy_channel_lower_bound = fix(ql_variance.energy_axis.low[0])
  ;packet.energy_channel_upper_bound = fix(ql_variance.energy_axis.high[0])

  ; number of structures
  packet.samples_per_variance = ql_variance.VAR_TIMES
  packet.number_of_samples = n_elements(ql_variance.VARIANCE)

  ; initialize pointer and prepare arrays for variance
  packet.dynamic_variance = ptr_new(bytarr(packet.number_of_samples))

  ; attach compressed values
  (*packet.dynamic_variance) = stx_km_compress(ql_variance.VARIANCE, $
      compression_param_k, compression_param_m, compression_param_s, error=error)
  
  ; stop if the compression params are faults
  if error then message, 'ERROR. Compression parameters are faulty.'

  return, packet
end



pro stx_telemetry_prepare_structure_ql_variance_write, ql_variance=ql_variance, $
  solo_slices=solo_slices, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)/8

  ; generate variance intermediate TM packet
  source_data = prepare_packet_structure_ql_variance_fsw(ql_variance=ql_variance, _extra=extra)

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
  n_structures = source_data.number_of_samples

  ; size of dynamic part (byte)
  dynamic_struct_size = 1

  ; max fitting samples per paket
  max_fitting_paket = UINT((max_packet_size - source_data.pkg_word_width.pkg_total_bytes_fixed)/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size

  ;Process ever sample with its trigger acumulator, detector index and delta_time
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

      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length += 9

      ; initialize the current packet size to the fixed packet length
      curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed
    endif

    ; run the following lines of code if we started a new 'SolO' packet
    if(solo_slices[-1].source_data eq ptr_new()) then begin
      ; copy the source data (prepare this 'partial' packet)
      partial_source_data = ptr_new(source_data)

      ; add general pakete information to 'SolO' slice
      solo_slices[-1].source_data = partial_source_data

      ; calculate the amount of fitting pakets
      if((n_structures-structure_idx)*dynamic_struct_size gt max_packet_size-curr_packet_size) then begin
        ; use all available space if more lightcurves than space are available
        fitting_pakets = max_fitting_paket
      endif else begin
        ; just use the needed space for the last few pakets
        fitting_pakets = n_structures-structure_idx
      endelse

      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_variance = ptr_new(bytarr(fitting_pakets)-1)

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).number_of_samples = 0

      ; update all packet data field lengths
      solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
      solo_slices[-1].data_field_length += (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length

      ; set the dynamic lenght to 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_variance = 0

    endif

    ; run the following lines of code when adding a new variance sample to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_variance)[(structure_idx MOD max_fitting_paket)] eq -1) then begin
      ; copy the slices to new pointers
      varaince_slice = reform((*source_data.dynamic_variance)[structure_idx])

      ; attach slices to paket
      (*(*solo_slices[-1].source_data).dynamic_variance)[(structure_idx MOD max_fitting_paket)] = varaince_slice

      ; adjust current packet size
      curr_packet_size += dynamic_struct_size
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size * 8
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size
      solo_slices[-1].data_field_length += dynamic_struct_size   
      
      ; increase dynamic lenght 
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_variance += dynamic_struct_size * 8

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


pro stx_telemetry_prepare_structure_ql_variance_read, asw_ql_variance=asw_ql_variance, $
  solo_slices=solo_slices, _extra=extra
  
  ; convert numbers to masks (only for the first packet)
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).detector_mask, detector_mask=detector_mask
    
  ; init counter for number of structures
  total_number_of_structures=0
  samples_per_variance=(*solo_slices[0].source_data).samples_per_variance
  
  ; get compression params
  compression_param_k = fix(ishft((*solo_slices[0].source_data).compression_schema_accum,-3) and 7)
  compression_param_m = fix((*solo_slices[0].source_data).compression_schema_accum and 7)
  compression_param_s = fix(ishft((*solo_slices[0].source_data).compression_schema_accum,-6) and 3)
  
  ; get energy axis
  energy_mask=stx_mask2bits((*solo_slices[0].source_data).energy_mask ,mask_length=32, /reverse)
  index = where(energy_mask eq 1)
  edges=[index[0],index[-1]]
  ;edges=[(*solo_slices[0].source_data).energy_channel_lower_bound, $
  ;  (*solo_slices[0].source_data).energy_channel_upper_bound]
  energy_axis=stx_construct_energy_axis(energy_edges=edges, select=[0,1])
  
  
  for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin
    
    ; count total_number_of_structures
    total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_of_samples   
    
    ; init slices
    slice_variance = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_variance)),$
      compression_param_k, compression_param_m, compression_param_s)
      
    ; append the slices to the final arrays
    if  solo_slice_idx eq 0 then begin
      var = slice_variance
    endif else begin
      var = [var, slice_variance]
    endelse
    
  endfor
      
  ; create time_axis
  coarse_time = (*solo_slices[0].source_data).coarse_time
  fine_time = (*solo_slices[0].source_data).fine_time
  time_axis=stx_telemetry_util_scet2axis(coarse_time=coarse_time, fine_time=fine_time, $
    nbr_structures=total_number_of_structures, $
    integration_time_in_s=(*solo_slices[0].source_data).integration_time/10.0)
  
  ;create new stx_asw_ql_variance object
  if(arg_present(asw_ql_variance)) then begin
    asw_ql_variance=stx_asw_ql_variance(total_number_of_structures)
    asw_ql_variance.time_axis=time_axis
    asw_ql_variance.energy_axis=energy_axis
    asw_ql_variance.samples_per_variance=samples_per_variance
    asw_ql_variance.variance=var
    asw_ql_variance.detector_mask=detector_mask
    asw_ql_variance.pixel_mask=pixel_mask
  endif
  
end



pro stx_telemetry_prepare_structure_ql_variance, ql_variance=ql_variance, $
  asw_ql_variance=asw_ql_variance, solo_slices=solo_slices, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_variance_write, ql_variance=ql_variance, $
      solo_slices=solo_slices, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_variance_read, solo_slices=solo_slices, $
      asw_ql_variance=asw_ql_variance, _extra=extra

  endelse

end

