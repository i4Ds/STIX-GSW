;+
; :description:
;   this routine generates the spectra quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    31
;   > Coarse Time (SCET)                    -                   4 octets
;   > Fine Time (SCET)                      -                   2 octets
;   > Integration Time                      -                   1 octet
;   > Compression Schema Spectra            -                   1 octet
;   > Compression Schema Trigger            -                   1 octet
;   > Spare block                           -                   4 bits
;   > Pixel Mask                            -                   12 bits
;   > Number of Structures (N)              -                   2 octet
;   > Spectra
;   > > Detector index                                          1 octet             per spectra (1xN)
;   > > Spectrum                                                32 octets           per spectra (32xN)
;   > > Trigger Accumulator                                     1 octet             per spectra (1xN)
;   > > Delta time                                              2 octets            per spectra (2xN)
;
; :categories:
;   simulation, writer, telemetry, quicklook, spectra
;
; :params:
;   spectra : in, required, type="stx_sim_ql_spectra"
;     the input spectra
;
; :keywords:
;   compression_param_k_sp : in, optional, type='int', default='4'
;     this is the compression parameter k (spectra), the number of exponent bits to be used
;
;   compression_param_m_sp : in, optional, type='int', default='4'
;     this is the compression parameter m (spectra), the number of exponent bits to be used
;
;   compression_param_s_sp : in, optional, type='int', default='0'
;     this is the compression parameter s (spectra), 1 implies the datum may be signed; = 0 if datum is always positive
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
;    01-Dec-2015 - Simon Marcin (FHNW), initial release
;    25-Jul-2016 - Simon Marcin (FHNW), prepared for read function
;    08-Aug-2016 - Simon Marcin (FHNW), added stx_fsw_spectra support
;    19-Sep-2016 - Simon Marcin (FHNW), added asw_ql_spectra
;    11-Oct-2016 - Simon Marcin (FHNW), changed writer & reader to use stx_fsw_m_ql_spectra
;-
function prepare_packet_structure_ql_spectra_fsw, ql_spectra=ql_spectra, $
  compression_param_k_sp=compression_param_k_sp, $
  compression_param_m_sp=compression_param_m_sp, $
  compression_param_s_sp=compression_param_s_sp, $
  compression_param_k_t=compression_param_k_t, $
  compression_param_m_t=compression_param_m_t, $
  compression_param_s_t=compression_param_s_t, $
  _extra=extra

  ; type checking
  ppl_require, in=ql_spectra, type='stx_fsw_m_ql_spectra'

  default, compression_param_k_t, 5
  default, compression_param_m_t, 3
  default, compression_param_s_t, 0
  default, compression_param_k_sp, 5
  default, compression_param_m_sp, 3
  default, compression_param_s_sp, 0

  ; generate empty light curves paket
  packet = stx_telemetry_packet_structure_ql_spectra()

  ; fill in the data
  packet.integration_time = ql_spectra.integration_time * 10

  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=ql_spectra.START_TIME
  packet.coarse_time = coarse_time
  packet.fine_time = fine_time

  ; s, kkk, mmm for spectrum
  packet.compression_schema_spectrum = stx_km_compression_params_to_schema(compression_param_k_sp,compression_param_m_sp,compression_param_s_sp)
  
  ; s, kkk, mmm for trigger accumulator
  packet.compression_schema_trigger = stx_km_compression_params_to_schema(compression_param_k_t,compression_param_m_t,compression_param_s_t)
  
  
  ; pixel mask gets converted to a number
  packet.pixel_mask=ql_spectra.pixel_mask[0]

  ; spare bits
  packet.spare_block = uint(0)

  ; number of structures
  time_bins = n_elements(ql_spectra.samples)
  energy_bins = 32 ; fixed for ql_spectra
  packet.number_of_structures = time_bins

  ; initialize pointer and prepare arrays for triggers and spectra values
  packet.dynamic_detector_index = ptr_new(bytarr(packet.number_of_structures))
  packet.dynamic_spectrum = ptr_new(bytarr(energy_bins, packet.number_of_structures))
  packet.dynamic_trigger_accumulator = ptr_new(bytarr(packet.number_of_structures))
  packet.dynamic_nbr_samples = ptr_new(intarr(packet.number_of_structures))
  
  
  
  ;Loop through all time bins
  for time_bin = 0L, time_bins-1 do begin
    
    if ql_spectra.samples[time_bin].DELTA_TIME eq 92 AND ql_spectra.samples[time_bin].detector_index eq 5 then begin
      print, 1
    endif
                
    ; compress spectra
    sub_spectra_compressed = stx_km_compress(ql_spectra.samples[time_bin].counts, $
      compression_param_k_sp, compression_param_m_sp, compression_param_s_sp)

    ; compress trigger accumulator
    sub_trigger_compressed = stx_km_compress(ql_spectra.samples[time_bin].trigger, $
      compression_param_k_t, compression_param_m_t, compression_param_s_t)
    
    ; attach subs to packet
    (*packet.dynamic_detector_index)[time_bin] = ql_spectra.samples[time_bin].detector_index
    (*packet.dynamic_spectrum)[*,time_bin] = reform(sub_spectra_compressed)
    (*packet.dynamic_trigger_accumulator)[time_bin] = reform(sub_trigger_compressed)
    ;fix nicky hochmuth ToDO check with Simon
    ;(*packet.dynamic_nbr_samples)[time_bin] = time_bin
    (*packet.dynamic_nbr_samples)[time_bin] = ql_spectra.samples[time_bin].DELTA_TIME / ql_spectra.integration_time

  endfor

  return, packet
end



pro stx_telemetry_prepare_structure_ql_spectra_write, solo_slices=solo_slices, $
   ql_spectra=ql_spectra, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)/8

  ; generate spectra intermediate TM packet (based on the input type)
  switch (ql_spectra.type) of
    'stx_fsw_m_ql_spectra': begin
      source_data = prepare_packet_structure_ql_spectra_fsw(ql_spectra=ql_spectra, $
        _extra=extra)
      break
    end
    'stx_asw_ql_spectra': begin
      ;source_data = prepare_packet_structure_ql_spectra_asw(_extra=extra)
      break
    end
    else: begin
      message, 'Unknown data packet type for spectra generation: ' + data_packet_type
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

  ; get the number of data samples
  n_structures = source_data.number_of_structures

  ; size of dynamic part
  dynamic_struct_size = 1+32+1+1 

  ; max fitting light_curves per paket
  max_fitting_paket = UINT((max_packet_size - source_data.pkg_word_width.pkg_total_bytes_fixed)/dynamic_struct_size)

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size

  ; counter_samples (used to increase the SCET by integration_time*counter)
  integration_time_offset = 0L
  
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

      ; initialize the current packet size to the fixed packet length
      curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed ; * 8 (already bytes)
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
        fitting_pakets = n_structures-structure_idx
      endelse

      ; update the SCET in each new packet 
      (*solo_slices[-1].source_data).coarse_time += (*source_data.dynamic_nbr_samples)[structure_idx]*((*solo_slices[-1].source_data).integration_time * 0.1) 
      
       integration_time_offset = (*source_data.dynamic_nbr_samples)[structure_idx]
      
      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_detector_index = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_spectrum = ptr_new(bytarr(32,fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_trigger_accumulator = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_nbr_samples = ptr_new(intarr(fitting_pakets)-1)

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).number_of_structures = 0

      ; update all packet data field lengths
      solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
      solo_slices[-1].data_field_length = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length

      ; Set the dynamic lenght to 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_detector_index = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_spectrum = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_trigger_accumulator = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_nbr_samples = 0
      
      ; add 9 (not 10?) bytes for TM Packet Data Header that is otherwise not accounted for
      solo_slices[-1].data_field_length += 9
     
    endif

    ; run the following lines of code when adding a new spectrum sample to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_spectrum)[0,(structure_idx MOD max_fitting_paket)] eq -1) then begin
      ; copy the slices to new pointers
      detector_index_slice = reform((*source_data.dynamic_detector_index)[structure_idx])
      spectrum_slice = reform((*source_data.dynamic_spectrum)[0:31,structure_idx])
      trigger_slice = reform((*source_data.dynamic_trigger_accumulator)[structure_idx])

      ; attach slices to paket
      (*(*solo_slices[-1].source_data).dynamic_detector_index)[(structure_idx MOD max_fitting_paket)] = detector_index_slice
      (*(*solo_slices[-1].source_data).dynamic_spectrum)[0:31,(structure_idx MOD max_fitting_paket)] = spectrum_slice
      (*(*solo_slices[-1].source_data).dynamic_trigger_accumulator)[(structure_idx MOD max_fitting_paket)] = trigger_slice
      ;(*(*solo_slices[-1].source_data).dynamic_delta_time)[(structure_idx MOD max_fitting_paket)] = delta_time_slice
      ; 23.Feb.2017 - simon marcin: changed from delta time to nbr_samples (always relative to the actual paket header)
      ;(*(*solo_slices[-1].source_data).dynamic_nbr_samples)[(structure_idx MOD max_fitting_paket)] = (*solo_slices[-1].source_data).number_of_structures
      
      (*(*solo_slices[-1].source_data).dynamic_nbr_samples)[(structure_idx mod max_fitting_paket)] = (*source_data.dynamic_nbr_samples)[structure_idx] - integration_time_offset

      
      ; adjust current packet size
      curr_packet_size += dynamic_struct_size
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size
      solo_slices[-1].data_field_length += dynamic_struct_size

      ; adjust number of attached structures
      (*solo_slices[-1].source_data).number_of_structures++
      

    endif
  endfor

  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end



pro stx_telemetry_prepare_structure_ql_spectra_read, solo_slices=solo_slices, $
  asw_ql_spectra=asw_ql_spectra, fsw_m_ql_spectra=fsw_m_ql_spectra, _extra=extra

  ; convert numbers to masks (only for the first packet)
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).pixel_mask, pixel_mask=pixel_mask

  ; init counter for number of structures
  total_number_of_structures=0

  ; get compression params
  
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_trigger, k=compression_param_k_t, m=compression_param_m_t, s=compression_param_s_t
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema_spectrum, k=compression_param_k_sp, m=compression_param_m_sp, s=compression_param_s_sp
 
  ; start_time as stx_time
  stx_telemetry_util_time2scet,coarse_time=(*solo_slices[0].source_data).coarse_time, $
    fine_time=(*solo_slices[0].source_data).fine_time, stx_time_obj=start_time, /reverse
    
  ; convert integration time from 1/10s to s
  integration_time = (*solo_slices[0].source_data).integration_time/10.0  
  
  ; reading the solo_sclice
  for solo_slice_idx = 0L, n_elements(solo_slices)-1 do begin

    ; init slices
    slice_spectrum = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_spectrum)),$
      compression_param_k_sp, compression_param_m_sp, compression_param_s_sp)

    slice_triggers = stx_km_decompress(ulong((*(*solo_slices[solo_slice_idx].source_data).dynamic_trigger_accumulator)),$
      compression_param_k_t, compression_param_m_t, compression_param_s_t)

    slice_detector_index = byte((*(*solo_slices[solo_slice_idx].source_data).dynamic_detector_index))
    slice_nbr_samples = uint((*(*solo_slices[solo_slice_idx].source_data).dynamic_nbr_samples))
    
    
    stx_telemetry_util_time2scet,coarse_time=(*solo_slices[solo_slice_idx].source_data).coarse_time, $
      fine_time=(*solo_slices[solo_slice_idx].source_data).fine_time, stx_time_obj=current_time, /reverse

    time_diff = uint(stx_time_diff(current_time, start_time, /abs))
    print, time_diff
    time_offset = uint(time_diff / integration_time)
    
    
    ; extrapolate the relative number of samples
    ; ToDo: Handle missing packets (create a gap in the nbr_samples)
    slice_nbr_samples += time_offset

    ; append the slices
    if  solo_slice_idx eq 0 then begin
      spectrum = slice_spectrum
      triggers = slice_triggers
      detector_index = slice_detector_index
      nbr_samples = slice_nbr_samples
    endif else begin
      spectrum = [[spectrum], [slice_spectrum]]
      triggers = [triggers, slice_triggers]
      detector_index = [detector_index, slice_detector_index]
      nbr_samples = [nbr_samples, slice_nbr_samples]
    endelse
    
  
     
    
    ; count total_number_of_structures
    total_number_of_structures += (*solo_slices[solo_slice_idx].source_data).number_of_structures

  endfor

  


  
  ;create new stx_asw_ql_spectra object
  if(arg_present(asw_ql_spectra)) then begin
;    asw_ql_spectra=stx_construct_asw_ql_spectra(time_axis=time_axis, spectrum=spectra_array, $
;      triggers=spectra_lt, pixel_mask=pixel_mask)  
  endif
  
  if(arg_present(fsw_m_ql_spectra)) then begin
    
    ; define sampke entry.
    ; ToDo: define this as a structure in a file
    sample = {$
      DETECTOR_INDEX  : byte(0), $
      COUNTS          : ulonarr(32), $
      TRIGGER         : ulong(0), $
      DELTA_TIME      : fix(0) $
    }
    
    ; create array of samples
    samples = replicate(sample, total_number_of_structures)
    for i=0L, total_number_of_structures-1 do begin
      samples[i].detector_index = reform(detector_index[i])
      samples[i].trigger = reform(triggers[i])
      ; 23.Jan 2017 simon marcin: delta_time relative to first data sample.
      samples[i].delta_time = reform(nbr_samples[i]*integration_time)
      samples[i].counts = reform(spectrum[*,i])
    endfor
    
    fsw_m_ql_spectra = {$
      type             : "stx_fsw_m_ql_spectra", $
      pixel_mask       : pixel_mask, $
      samples          : samples, $
      integration_time : integration_time, $
      start_time       : start_time $
    }

    
  endif
  
end


pro stx_telemetry_prepare_structure_ql_spectra, ql_spectra=ql_spectra, $
  asw_ql_spectra=asw_ql_spectra, fsw_m_ql_spectra=fsw_m_ql_spectra, $
  solo_slices=solo_slices, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_spectra_write, ql_spectra=ql_spectra, $
      solo_slices=solo_slices, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_spectra_read, solo_slices=solo_slices, $
      asw_ql_spectra=asw_ql_spectra, fsw_m_ql_spectra=fsw_m_ql_spectra, _extra=extra

  endelse

end

