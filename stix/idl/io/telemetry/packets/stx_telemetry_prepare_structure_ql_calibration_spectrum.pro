
;+
; :description:
;   this routine generates the calibration spectrum quicklook packet
;
;   PARAMETER                               VALUE               WIDTH               NOTE
;   ----------------------------------------------------------------------------------------------
;   APID-PID                                93                                      STIX auxiliary science data processing application
;   Packet Category                         12                                      Science
;   Packet data field length - 1            variable
;   Service Type                            21                                      Science data transfer
;   Service Subtype                         3                                       Science data report
;   SSID                                    41                                      Calibration accumulators
;   > Start Time (seconds)                  -                   4 octets
;   > Duration (seconds)                    -                   4 octets
;   > Quiet Time                            -                   2 octets
;   > Live Time Accumulator                 -                   4 octets
;   > Average Temperature                   -                   2 octets
;   > Compression Schema                    -                   1 octet
;   > Spectrum 1 Definition                 -                   4 octets
;   > > Subspectra                                              2 octets            per det/pxl/subspectrum
;                                                               + Ni octets         data (for all included det/pxl/subspectrum)
;                                                                                   COMPRESSED
;
; :categories:
;   simulation, writer, telemetry, quicklook
;
; :params:
;   calibration_spectrum : in, required, type="stx_sim_calibration_spectrum"
;     the input calibration spectrum
;
; :keywords:
;   qt : in, optional, type='ulong', default='1000'
;     this is the quiet time gate time in milliseconds; to be removed
;
;   average_temperature : in, optional, type='ulong', default='0'
;     this is the average detector temperature
;
;   compression_param_k : in, optional, type='int', default='4'
;     this is the compression parameter k, the number of exponent bits to be used
;
;   compression_param_m : in, optional, type='int', default='4'
;     this is the compression parameter m, the number of exponent bits to be used
;
;   compression_param_s : in, optional, type='int', default='0'
;     this is the compression parameter s, 1 implies the datum may be signed; = 0 if datum is always positive
;
;   subspectra_definition : in, optional, type='intarr(n, 3)', default='[0,4,256']
;     this is the calibrations subspectrum definition:
;     [Li, Wi, Ni]: Li is lower energy bound, Wi is scaled energy channels to sum per spectral point, Ni is number
;     of spectral points in this subspectrum
;
;   detector_mask : in, optional, type='ulong', default='ulong(2L^32)-1'
;     the mask of included detectors
;
;   pixel_mask : in, optional, type='int', default='2^13-1'
;     the mask of included pixels
;
; :history:
;    27-May-2015 - Laszlo I. Etesi (FHNW), initial release
;    
;-
function prepare_packet_structure_ql_calibration_spectrum_sim, calibration_spectrum=calibration_spectrum, $
  qt=qt, average_temperature=average_temperature, $
  compression_param_k=compression_param_k, $
  compression_param_m=compression_param_m, $
  compression_param_s=compression_param_s, $
  subspectra_definition=subspectra_definition, pixel_mask=pixel_mask, detector_mask=detector_mask, _extra=extra

  ; type checking
  ppl_require, in=calibration_spectrum, type='stx_sim_calibration_spectrum'

  default, qt, 1000 ; microseconds
  default, average_temperature, 0
  default, compression_param_k, 5
  default, compression_param_m, 3
  default, compression_param_s, 0
  default, pixel_mask, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]; [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0] ; [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
  default, detector_mask, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]; [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ; [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

  ; generate empty calibration spectrum packet
  packet = stx_telemetry_packet_structure_ql_calibration_spectrum()

  ; fill in the data
  packet.start_time = ulong(stx_time2scet(calibration_spectrum.start_time))
  packet.duration = ulong(stx_time2scet(calibration_spectrum.end_time)) - packet.start_time
  packet.quiet_time = qt
  packet.live_time = ulong(calibration_spectrum.live_time) ; <- this is an invalid conversion from time to counts!
  packet.average_temperature = average_temperature

  ; s, kkk, mmm
  packet.compression_schema = ishft(compression_param_s, 6) or ishft(compression_param_k, 3) or compression_param_m

  ; the detector and pixel mask are converted to a number; the first entry in the array will become the HSB in the number
  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, output=packet, detector_mask=detector_mask, tag='detector_mask'
  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, output=packet, pixel_mask=pixel_mask, tag='pixel_mask'

  ; used to read out subspectras
  subspectra_definition_dimensions = size(subspectra_definition)
  subspectra_definition_dimension = subspectra_definition_dimensions[0] eq 1 ? 1 : subspectra_definition_dimensions[2]

  ; generate subspectra mask
  subspectrum_mask = bytarr(8)
  subspectrum_mask[0:subspectra_definition_dimension-1] = 1

  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, output=packet, subspectrum_mask=subspectrum_mask, tag='subspectrum_mask'

  tags = strlowcase(tag_names(packet))

  ; read pixel and detector indeces
  pixels = where(pixel_mask eq 1, n_pixels)
  detectors = where(detector_mask eq 1, n_detectors)

  ; initialize pointer and prepare array for subspectra
  packet.subspectra = ptr_new(ptrarr(subspectra_definition_dimension))

  for sdidx = 0L, subspectra_definition_dimension-1 do begin
    li = subspectra_definition[sdidx * 3]
    wi = subspectra_definition[sdidx * 3 + 1]
    ni = subspectra_definition[sdidx * 3 + 2]

    ; generate subspectrum id
    subspectrum_name = 'subspectrum_definition_' + trim(string(sdidx+1))

    ; write subspectrum definition
    stx_telemetry_encode_decode_structure_ql_calibration_spectrum, output=packet, ni_wi_li=[ni, wi, li], tag=subspectrum_name

    ; calculate subspectrum
    sub_spectrum = stx_fsw_calibration_spectrum2sub_spectrum(calibration_spectrum, detector_mask=detector_mask, pixel_mask=pixel_mask, li=li, wi=wi, ni=ni, _extra=extra)

    ; compress subspectrum...
    sub_spectrum_compressed = stx_km_compress(sub_spectrum, compression_param_k, compression_param_m, compression_param_s)

    ; prepend pixel id, detector id and subspectrum id:
    ; TODO: not fixed to 12 and 32, use number of bits in mask
    sub_spectrum_compressed_prepended = lonarr(2 + ni, 12, 32)

    ; initialize all values with -1 to distinguish between "no data" and valid zero data
    sub_spectrum_compressed_prepended[*] = -1

    ; ugly, may be used to transform from pixel - detector - subspectrum to detector - pixel - subspectrum (see spec)
    for pxl_idx = 0L, n_pixels-1 do begin
      for det_idx = 0L, n_detectors-1 do begin
        ; the detector id from 1 - 32 is used in TMTC with LSB=1, MSB=32 [32, 31, ..., 2, 1]
        ; NB: the routine stx_telemetry_encode_decode_ql_... will make sure the id (1 - 32) -> idx (0 - 31)
        det_id = 32 - detectors[det_idx]

        ; the pixel index from 0 - 11 is used in TMTC with LSB=0, MSB=11 [11, 10, ..., 1, 0]
        pxl_id = 11 - pixels[pxl_idx]

        stx_telemetry_encode_decode_structure_ql_calibration_spectrum, output=pds_id, detector_pixel_subspectrum_address=[det_id, pxl_id, sdidx]

        print, [det_id, pxl_id, sdidx]
        print, det_idx
        print, pxl_idx
        print, detectors[det_idx]
        print, pixels[pxl_idx]

        ; write the data from a reduced spectrum matrix to a "full sized" matrix. The pixel and detector
        ; indices must be converted
        ; NB: same indices for the data array as for the detector and pixel mask (descending!)
        sub_spectrum_compressed_prepended[*, pixels[pxl_idx], detectors[det_idx]] = [pds_id, reform(sub_spectrum_compressed[*, pxl_idx, det_idx])]
      endfor
    endfor

    ; ...and attach it to packet
    ((*packet.subspectra)[sdidx]) = ptr_new(reform(sub_spectrum_compressed_prepended))
  endfor

  return, packet
end


function prepare_packet_structure_ql_calibration_spectrum_fsw, ql_calibration_spectrum=ql_calibration_spectrum, $
  compression_param_k=compression_param_k, compression_param_m=compression_param_m, $
  compression_param_s=compression_param_s, subspectra_definition=subspectra_definition, _extra=extra

  ; type checking
  ppl_require, in=ql_calibration_spectrum, type='stx_fsw_m_calibration_spectrum'

  default, compression_param_k, 5
  default, compression_param_m, 3
  default, compression_param_s, 0
  default, subspectra_definition, [[0,4,32], [128,4,32], [256,4,32], [384,4,32], [512,4,32], [640,4,32], [768,4,32], [896,4,32]]

  ; generate empty calibration spectrum packet
  packet = stx_telemetry_packet_structure_ql_calibration_spectrum()

  ; fill in the data

  ; Error in fsw:
  ;packet.duration = ulong(stx_time_diff(ql_calibration_spectrum.START_TIME,ql_calibration_spectrum.END_TIME))
  packet.duration = 10

  packet.quiet_time = 0 ; toDo: get value out of fsw
  packet.live_time = ulong(ql_calibration_spectrum.live_time) ;toDo: verify
  packet.average_temperature = 0 ; toDo: get value out of fsw

  ; convert time to scet
  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=ql_calibration_spectrum.START_TIME, reverse=reverse
  packet.coarse_time = coarse_time
  ;packet.fine_time = fine_time

  ; s, kkk, mmm
  packet.compression_schema = stx_km_compression_params_to_schema(compression_param_k, compression_param_m, compression_param_s)

  ;toDo: Only workaround to include pixel- and detector mask
  if(not tag_exist(ql_calibration_spectrum,'pixel_mask')) then $
    ql_calibration_spectrum=add_tag(ql_calibration_spectrum,[1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b,1b],'pixel_mask')
  if(not tag_exist(ql_calibration_spectrum,'detector_mask')) then $
    ql_calibration_spectrum=add_tag(ql_calibration_spectrum,$
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],'detector_mask')


  ; the detector and pixel mask are converted to a number; the first entry in the array will become the HSB in the number
  packet.detector_mask=stx_mask2bits(ql_calibration_spectrum.detector_mask,mask_length=32)
  packet.pixel_mask=stx_mask2bits(ql_calibration_spectrum.pixel_mask,mask_length=12)
  ;stx_telemetry_util_encode_decode_structure, output=packet, detector_mask=ql_calibration_spectrum.detector_mask, tag='detector_mask'
  ;stx_telemetry_util_encode_decode_structure, output=packet, pixel_mask=ql_calibration_spectrum.pixel_mask, tag='pixel_mask'

  ;get number of subspectras
  subspectra_definition_dimensions = size(subspectra_definition)
  subspectra_definition_dimension = subspectra_definition_dimensions[0] eq 1 ? 1 : subspectra_definition_dimensions[2]

  ; generate subspectra mask
  subspectrum_mask = bytarr(8)
  subspectrum_mask[0:subspectra_definition_dimension-1] = 1
  packet.subspectrum_mask=stx_mask2bits(subspectrum_mask, mask_length=8)

  ; wirte subspectra entries
  if(subspectrum_mask[0]) then packet.s1_nbr_points =     subspectra_definition[2,0]-1
  if(subspectrum_mask[0]) then packet.s1_nbr_channels =   subspectra_definition[1,0]-1
  if(subspectrum_mask[0]) then packet.s1_lowest_channel = subspectra_definition[0,0]
  if(subspectrum_mask[1]) then packet.s2_nbr_points =     subspectra_definition[2,1]-1
  if(subspectrum_mask[1]) then packet.s2_nbr_channels =   subspectra_definition[1,1]-1
  if(subspectrum_mask[1]) then packet.s2_lowest_channel = subspectra_definition[0,1]
  if(subspectrum_mask[2]) then packet.s3_nbr_points =     subspectra_definition[2,2]-1
  if(subspectrum_mask[2]) then packet.s3_nbr_channels =   subspectra_definition[1,2]-1
  if(subspectrum_mask[2]) then packet.s3_lowest_channel = subspectra_definition[0,2]
  if(subspectrum_mask[3]) then packet.s4_nbr_points =     subspectra_definition[2,3]-1
  if(subspectrum_mask[3]) then packet.s4_nbr_channels =   subspectra_definition[1,3]-1
  if(subspectrum_mask[3]) then packet.s4_lowest_channel = subspectra_definition[0,3]
  if(subspectrum_mask[4]) then packet.s5_nbr_points =     subspectra_definition[2,4]-1
  if(subspectrum_mask[4]) then packet.s5_nbr_channels =   subspectra_definition[1,4]-1
  if(subspectrum_mask[4]) then packet.s5_lowest_channel = subspectra_definition[0,4]
  if(subspectrum_mask[5]) then packet.s6_nbr_points =     subspectra_definition[2,5]-1
  if(subspectrum_mask[5]) then packet.s6_nbr_channels =   subspectra_definition[1,5]-1
  if(subspectrum_mask[5]) then packet.s6_lowest_channel = subspectra_definition[0,5]
  if(subspectrum_mask[6]) then packet.s7_nbr_points =     subspectra_definition[2,6]-1
  if(subspectrum_mask[6]) then packet.s7_nbr_channels =   subspectra_definition[1,6]-1
  if(subspectrum_mask[6]) then packet.s7_lowest_channel = subspectra_definition[0,6]
  if(subspectrum_mask[7]) then packet.s8_nbr_points =     subspectra_definition[2,7]-1
  if(subspectrum_mask[7]) then packet.s8_nbr_channels =   subspectra_definition[1,7]-1
  if(subspectrum_mask[7]) then packet.s8_lowest_channel = subspectra_definition[0,7]

  ;calculate number of structures in the packet
  nbr_detectors = total(ql_calibration_spectrum.detector_mask)
  nbr_pixels = total(ql_calibration_spectrum.pixel_mask)
  packet.number_of_structures = subspectra_definition_dimension*nbr_detectors*nbr_pixels

  ; initialize pointer and prepare arrays
  packet.dynamic_spare = ptr_new(bytarr(packet.number_of_structures))
  packet.dynamic_detector_id = ptr_new(bytarr(packet.number_of_structures))
  packet.dynamic_pixel_id = ptr_new(bytarr(packet.number_of_structures))
  packet.dynamic_subspectra_id = ptr_new(bytarr(packet.number_of_structures))
  packet.dynamic_number_points = ptr_new(uintarr(packet.number_of_structures))
  packet.dynamic_spectral_points = ptr_new(list())

  ; init structure counter
  counter = 0UL

  ;Loop through all data samples

  total_count = 1UL
  compress_count = 1UL

  for subspectra_id = 0L, subspectra_definition_dimension-1 do begin

    ; get subspectrum parameters
    e_start = subspectra_definition[0,subspectra_id]
    e_step = subspectra_definition[1,subspectra_id]
    e_nx = subspectra_definition[2,subspectra_id]

    for detector_id = 0L, nbr_detectors-1  do begin
      for pixel_id = 0L, nbr_pixels-1 do begin

        ; wirte IDs
        (*packet.dynamic_detector_id)[counter] = detector_id
        (*packet.dynamic_pixel_id)[counter] = pixel_id
        (*packet.dynamic_subspectra_id)[counter] = subspectra_id
        (*packet.dynamic_number_points)[counter] = subspectra_definition[2,subspectra_id]

        ; add new array to list
        (*packet.dynamic_spectral_points).add, bytarr(e_nx)

        ; sum and compress energy slices according to subspectra definition
        for energy_id = 0, e_nx-1 do begin
          from = e_start + e_step*energy_id
          to = from + e_step -1
          s_point = total(ql_calibration_spectrum.accumulated_counts[from:to,pixel_id,detector_id], /preserve_type  )
          total_count += s_point

          s_point = stx_km_compress(s_point,compression_param_k,compression_param_m,compression_param_s)

          compress_count += s_point

          ((*packet.dynamic_spectral_points)[counter,energy_id]) = s_point

        endfor

        ; increase structure counter
        counter+=1

      endfor
    endfor
  endfor

  return, packet

end




pro stx_telemetry_prepare_structure_ql_calibration_spectrum_write, solo_slices=solo_slices, $
  ql_calibration_spectrum=ql_calibration_spectrum, _extra=extra

  solo_source_packet_header = stx_telemetry_packet_structure_solo_source_packet_header()

  ; read how many bits are left for the source data in bits
  max_packet_size = abs(solo_source_packet_header.pkg_word_width.source_data)

  ; generate calibration spectrum intermediate TM packet
  source_data = prepare_packet_structure_ql_calibration_spectrum_fsw(ql_calibration_spectrum=ql_calibration_spectrum, $
    _extra=extra)

  ; set the sc time of the solo_header packet
  solo_source_packet_header.coarse_time = source_data.coarse_time

  ; copy all header information to solo packet
  tags = strlowcase(tag_names(source_data))

  for tag_idx = 0L, n_tags(source_data)-1 do begin
    tag = tags[tag_idx]

    if(~stregex(tag, 'header_.*', /bool)) then continue

    tag_val = source_data.(tag_idx)
    solo_source_packet_header.(tag_index(solo_source_packet_header, (stregex(tag, 'header_(.*)', /extract, /subexpr))[1])) = tag_val
  endfor

  ; get the number of structures
  n_structures = source_data.number_of_structures

  ; dynamic size is depending on subspectra definition
  list_nx = list()
  list_nx.add, source_data.s1_nbr_points
  list_nx.add, source_data.s2_nbr_points
  list_nx.add, source_data.s3_nbr_points
  list_nx.add, source_data.s4_nbr_points
  list_nx.add, source_data.s5_nbr_points
  list_nx.add, source_data.s6_nbr_points
  list_nx.add, source_data.s7_nbr_points
  list_nx.add, source_data.s8_nbr_points

  ; max fitting dynamic elements per paket
  dynamic_struct_size = intarr(8)
  max_fitting_paket = intarr(8)
  for i=0, 7 do begin
    dynamic_struct_size[i] = ((list_nx[i]+1) + 1 + 1+2) * 8
    max_fitting_paket[i] = UINT((max_packet_size - source_data.pkg_word_width.pkg_total_bytes_fixed)/dynamic_struct_size[i])
  endfor

  ; set curr_packet_size = max_packet_size in order to create a new packet
  curr_packet_size = max_packet_size

  ; init of subspectra variable
  current_id = 0

  ;Process ever spectralpoint
  for structure_idx = 0L, n_structures-1 do begin

    ; check if we have an overflow; if so -> start a new packet
    if(curr_packet_size + dynamic_struct_size[(*source_data.dynamic_subspectra_id)[structure_idx]] gt max_packet_size) then begin
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
      curr_packet_size = source_data.pkg_word_width.pkg_total_bytes_fixed
    endif

    ; run the following lines of code if we started a new 'SolO' packet
    if(solo_slices[-1].source_data eq ptr_new()) then begin
      ; copy the source data (prepare this 'partial' packet). copy it so that the fields are pre-initialized
      partial_source_data = ptr_new(source_data)

      ; add general pakete information to 'SolO' slice
      solo_slices[-1].source_data = partial_source_data

      ; calculate the amount of fitting packets
      fitting_pakets = 0
      dyn_size = 0
      dynamic_spectral_points = list()
      for i=structure_idx, n_structures-1 do begin
        dyn_size+=dynamic_struct_size[(*source_data.dynamic_subspectra_id)[i]]
        if(curr_packet_size+dyn_size gt max_packet_size) then break
        fitting_pakets+=1
        dynamic_spectral_points.add, bytarr(list_nx[(*source_data.dynamic_subspectra_id)[i]] + 1)
      endfor

      ; initialize dynamic arrays
      (*solo_slices[-1].source_data).dynamic_spare = ptr_new(bytarr(fitting_pakets))
      (*solo_slices[-1].source_data).dynamic_detector_id = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_pixel_id = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_subspectra_id = ptr_new(bytarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_number_points = ptr_new(uintarr(fitting_pakets)-1)
      (*solo_slices[-1].source_data).dynamic_spectral_points = ptr_new(list())

      ; initialize number_of_structures
      (*solo_slices[-1].source_data).number_of_structures = 0
      current_id = 0

      ; update all packet data field lengths
      solo_slices[-1].pkg_word_width.source_data = (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed * 8
      solo_slices[-1].data_field_length += (*solo_slices[-1].source_data).pkg_word_width.pkg_total_bytes_fixed
      (*solo_slices[-1].source_data).header_data_field_length = solo_slices[-1].data_field_length

      ; set the dynamic lenght to 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_spare = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_detector_id = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_pixel_id = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_subspectra_id = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_number_points = 0
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_spectral_points = 0

    endif

    ; run the following lines of code when adding a new set of spectral points to an existing packet that has space left
    if((*(*solo_slices[-1].source_data).dynamic_detector_id)[current_id] eq -1) then begin

      ; get spectrum_id
      spec_id = (*source_data.dynamic_subspectra_id)[structure_idx]

      ; attach slices to paket
      (*(*solo_slices[-1].source_data).dynamic_detector_id)[current_id] = (*source_data.dynamic_detector_id)[structure_idx]
      (*(*solo_slices[-1].source_data).dynamic_pixel_id)[current_id] = (*source_data.dynamic_pixel_id)[structure_idx]
      (*(*solo_slices[-1].source_data).dynamic_subspectra_id)[current_id] = (*source_data.dynamic_subspectra_id)[structure_idx]
      (*(*solo_slices[-1].source_data).dynamic_number_points)[current_id] = (*source_data.dynamic_number_points)[structure_idx]
      (*(*solo_slices[-1].source_data).dynamic_spectral_points).add, (*source_data.dynamic_spectral_points)[structure_idx]

      ; adjust current packet size
      curr_packet_size += dynamic_struct_size[spec_id]
      solo_slices[-1].pkg_word_width.source_data += dynamic_struct_size[spec_id] * 8
      (*solo_slices[-1].source_data).header_data_field_length += dynamic_struct_size[spec_id]
      solo_slices[-1].data_field_length += dynamic_struct_size[spec_id] / 8

      ; increase dynamic lenght
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_spare += 4
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_detector_id += 5
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_pixel_id += 4
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_subspectra_id += 3
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_number_points += 16
      (*solo_slices[-1].source_data).pkg_word_width.dynamic_spectral_points += list_nx[spec_id] * 8

      ; adjust number of attached structures
      (*solo_slices[-1].source_data).number_of_structures++
      current_id++

    endif
  endfor

  ; update segementation flag
  if(n_elements(solo_slices) eq 1) then solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 3
  if(n_elements(solo_slices) gt 1) then begin
    solo_slices[0].SEGMENTATION_GROUPING_FLAGS = 1
    solo_slices[-1].SEGMENTATION_GROUPING_FLAGS = 2
  endif

end

;+
; :history:
;    27-May-2015 - Laszlo I. Etesi (FHNW), initial release
;    08-Mar-2019 - ECMD (Graz), fill in data to array of maximum size (8 Subspectra x 12 Pixels x 32 Detectors)
;    
;-
pro stx_telemetry_prepare_structure_ql_calibration_spectrum_read, solo_slices=solo_slices, $
  asw_ql_calibration_spectrum=asw_ql_calibration_spectrum, $
  fsw_m_calibration_spectrum=fsw_m_calibration_spectrum, _extra=extra

  ; convert numbers to masks (only for the first packet)
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).detector_mask, detector_mask=detector_mask
  stx_telemetry_util_encode_decode_structure, $
    input=(*solo_slices[0].source_data).subspectrum_mask, subspectrum_mask=subspectrum_mask

  loop_p = 12
  loop_d = 32
  loop_s = 8


  ; dynamic size is depending on subspectra definition
  nbr_spec_poins = intarr(8)
  nbr_spec_poins[0]= (*solo_slices[0].source_data).s1_nbr_points + 1
  nbr_spec_poins[1]= (*solo_slices[0].source_data).s2_nbr_points + 1
  nbr_spec_poins[2]= (*solo_slices[0].source_data).s3_nbr_points + 1
  nbr_spec_poins[3]= (*solo_slices[0].source_data).s4_nbr_points + 1
  nbr_spec_poins[4]= (*solo_slices[0].source_data).s5_nbr_points + 1
  nbr_spec_poins[5]= (*solo_slices[0].source_data).s6_nbr_points + 1
  nbr_spec_poins[6]= (*solo_slices[0].source_data).s7_nbr_points + 1
  nbr_spec_poins[7]= (*solo_slices[0].source_data).s8_nbr_points + 1
  nbr_sum_channels = intarr(8)
  nbr_sum_channels[0]= (*solo_slices[0].source_data).s1_nbr_channels + 1
  nbr_sum_channels[1]= (*solo_slices[0].source_data).s2_nbr_channels + 1
  nbr_sum_channels[2]= (*solo_slices[0].source_data).s3_nbr_channels + 1
  nbr_sum_channels[3]= (*solo_slices[0].source_data).s4_nbr_channels + 1
  nbr_sum_channels[4]= (*solo_slices[0].source_data).s5_nbr_channels + 1
  nbr_sum_channels[5]= (*solo_slices[0].source_data).s6_nbr_channels + 1
  nbr_sum_channels[6]= (*solo_slices[0].source_data).s7_nbr_channels + 1
  nbr_sum_channels[7]= (*solo_slices[0].source_data).s8_nbr_channels + 1
  lowest_channel = intarr(8)
  lowest_channel[0]= (*solo_slices[0].source_data).s1_lowest_channel
  lowest_channel[1]= (*solo_slices[0].source_data).s2_lowest_channel
  lowest_channel[2]= (*solo_slices[0].source_data).s3_lowest_channel
  lowest_channel[3]= (*solo_slices[0].source_data).s4_lowest_channel
  lowest_channel[4]= (*solo_slices[0].source_data).s5_lowest_channel
  lowest_channel[5]= (*solo_slices[0].source_data).s6_lowest_channel
  lowest_channel[6]= (*solo_slices[0].source_data).s7_lowest_channel
  lowest_channel[7]= (*solo_slices[0].source_data).s8_lowest_channel

  ; create subspectra_definition
  subspectra_definition=intarr(3,loop_S)

  ; create a list of subspectra arrays
  ; we have to use a pointer array as editing the prepared arrays in a list does not work
  subspectra = ptrarr(loop_S)
  for i=0, loop_S-1 do begin
    subspectra_definition[*,i] = [lowest_channel[i], nbr_sum_channels[i], nbr_spec_poins[i]]
    subspectra[i] = ptr_new(lonarr(nbr_spec_poins[i] ,loop_P,loop_D),/no_copy)
  endfor

  ; init counter for number of structures
  total_number_of_structures=0
  det_id = 0
  pix_id = 0
  spc_id = 0

  ; get compression params
  stx_km_compression_schema_to_params, (*solo_slices[0].source_data).compression_schema, k=compression_param_k, m=compression_param_m, s=compression_param_s

  ; get other static information out of header
  coarse_time = (*solo_slices[0].source_data).coarse_time
  duration = (*solo_slices[0].source_data).duration
  quiet_time = (*solo_slices[0].source_data).quiet_time
  live_time = (*solo_slices[0].source_data).live_time
  average_temperature = (*solo_slices[0].source_data).average_temperature

  ; reading the solo_slices
  for solo_slice_idx = 0L, (size(solo_slices, /DIM))[0]-1 do begin

    ; count total_number_of_structures
    total_number_of_structures+=(*solo_slices[solo_slice_idx].source_data).number_of_structures


    for i=0L, (*solo_slices[solo_slice_idx].source_data).number_of_structures-1 do begin

      det_idx = (*(*solo_slices[solo_slice_idx].source_data).dynamic_detector_id)[i]-1
      pix_idx = (*(*solo_slices[solo_slice_idx].source_data).dynamic_pixel_id)[i]
      spc_idx = (*(*solo_slices[solo_slice_idx].source_data).dynamic_subspectra_id)[i]

      ; attach spectral points to subspectra list
      (*subspectra[spc_idx])[*,pix_idx,det_idx] = stx_km_decompress($
        reform((*(*solo_slices[solo_slice_idx].source_data).dynamic_spectral_points)[i]), $
        compression_param_k, compression_param_m, compression_param_s)

    endfor

  endfor

  ; create time
  stx_telemetry_util_time2scet,coarse_time=coarse_time, fine_time=0, stx_time_obj=t0, /reverse
  end_time = stx_time_add(t0, seconds=duration)


  ;create new stx_asw_ql_lightcurve object
  if(arg_present(asw_ql_calibration_spectrum)) then begin
    calsubspec = list()
    for i=0, loop_S-1 do begin
      calsubspec.add, stx_asw_ql_calibration_subspectrum(spectral_points=(*subspectra[i]), $
        subspectra_definition=subspectra_definition[*,i], pixel_mask=pixel_mask, detector_mask=detector_mask)
    endfor

    asw_ql_calibration_spectrum=stx_asw_ql_calibration_spectrum(calsubspec=calsubspec, $
      start_time=t0, end_time=end_time)
  endif



end

pro stx_telemetry_prepare_structure_ql_calibration_spectrum, solo_slices=solo_slices, $
  ql_calibration_spectrum=ql_calibration_spectrum, asw_ql_calibration_spectrum=asw_ql_calibration_spectrum, $
  fsw_m_calibration_spectrum=fsw_m_calibration_spectrum, _extra=extra

  ; if solo_slices is empty we write telemetry
  if n_elements(solo_slices) eq 0 then begin
    stx_telemetry_prepare_structure_ql_calibration_spectrum_write, solo_slices=solo_slices, $
      ql_calibration_spectrum=ql_calibration_spectrum, _extra=extra

    ; if solo_slices contains data, we are reading telemetry
  endif else begin
    stx_telemetry_prepare_structure_ql_calibration_spectrum_read, solo_slices=solo_slices, $
      asw_ql_calibration_spectrum=asw_ql_calibration_spectrum, $
      fsw_m_calibration_spectrum=fsw_m_calibration_spectrum, _extra=extra
  endelse
end

