;+
; :description:
;   transforms the ASW/FSW SIM format (32x12x32 [e,p,d]) to the FPGA format (12x32x32 [p,d,e])
;-
function _transform_32x12x32to12x32x32, acc_32x12x32, n_times=n_times
  ; extract dimensions
  acc_dim = size(acc_32x12x32.accumulated_counts)
  n_energies = acc_dim[1]
  n_pixels = acc_dim[2]
  n_detectors = acc_dim[3]
  n_times = acc_dim[0] eq 4 ? acc_dim[4] : 1

  ; the accumulators format is e(32), p(12), d(32), t(N); but the desired
  ; FPGA format is p(12), D(32), E(32), t(N)
  ; copy accumulator structure
  acc_12x32x32 = { $
    type                : 'all123232', $
    time_axis           : acc_32x12x32.time_axis, $
    energy_axis         : acc_32x12x32.energy_axis, $
    accumulated_counts  : ulonarr(12,32,32,n_times) $
  }

  ; stupid copy-over of counts
  for nt_i = 0L, n_times-1 do begin
    for e_i = 0L, n_energies-1 do begin
      for p_i = 0L, n_pixels-1 do begin
        for d_i = 0L, n_detectors-1 do begin
          acc_12x32x32.accumulated_counts[p_i, d_i, e_i, nt_i] = acc_32x12x32.accumulated_counts[e_i, p_i, d_i, nt_i]
        endfor
      endfor
    endfor
  endfor

  return, acc_12x32x32
end

;+
; :description:
;   This function converts a hex string to a binary/array mask.
;   The hex string is interpreted as LSB to MSB -> array_idx_0 to array_idx_n -> det_id_0 - det_id_n (same for detectors, pixels, energiers)
;   0x1 -> [1,0,0,...,0], detector id 1
;   0x80000000 -> [0,0,0,...,1], detector id 32
;
; :params:
;   hex : in, required, type='string'
;     This is the hex string to be converted to a mask; max lenght is 8 digits
;
; :keywords:
;   pixel : in, optional, type='boolean', default='0'
;     If set, the mask will have length 12, otherwise length 32
;
; :returns:
;   A 12 or 32 element array with ones and zeros used as a mask for
;   enabling/disabling detectors, pixels, or energies
;-
function _str_hex2byte_mask, hex, pixel=pixel
  default, range, [0,-1]

  if(keyword_set(pixel)) then range = [0, 11]

  number = 0L
  reads, hex, number, format='(Z)'

  stx_telemetry_util_encode_decode_structure, input=number, detector_mask=mask

  return, (reverse(mask))[range[0]:range[1]]
end

;+
; :description:
;   Reverse function to _str_hex2_byte_mask
;
; :params:
;   mask : in, required, type='bytarr(12) or bytarr(32)'
;     This is the array to be converted to a list of ids
;
; :keywords:
;   pixel : in, optional, type='boolean', default='0'
;     If set, the resulting hex string will be of length 3, otherwise 8
;
; :returns:
;   An ASCII representation in hex of the input mask
;-
function _byte_mask2hex_str, mask, pixel=pixel
  default, pad, 8

  if(keyword_set(pixel)) then pad = 3

  stx_telemetry_util_encode_decode_structure, input=number, detector_mask=mask, output=number, detector_mask=reverse(mask)

  return, to_hex(number, pad)
end

;+
; :description:
;   This routine converts a mask to an array of selected ids
;   The mask is interpreted as such: [1,0,0,...,9] -> id 1 (for detectors/energies)
;   or id 0 for pixels
;
; :params:
;   mask : in, required, type='bytarr(12) or bytarr(32)'
;     This is the array to be converted to a list of ids
;
; :keywords:
;   pixel : in, optional, type='boolean', default='0'
;     If set, the ids are not shifted, otherwise ids are shifted
;     by 1 (det/chnl: 1-32, pxl: 0-11)
;
; :returns:
;   An array of ids
;-
function _mask2id, mask, pixel=pixel
  default, shft, 1
  if(keyword_set(pixel)) then shft = 0

  ids = where(mask eq 1, count) + shft

  if(count eq 0) then return, -1 $
  else if(n_elements(ids) eq 1) then return, ids[0] $
  else return, ids
end

;+
; :description:
;   This routine converts an array of numbers to a compact array of strings
;
; :params:
;   arr : in, required, type='array of numbers'
;     This is the array to be converted to an array of strings
;
; :returns:
;   A compact array of strings
;-
function _pretty_nbr_array, arr
  return, '[' + trim(arr2str(trim(string(fix(arr))), delim=',')) + ']'
end

pro stx_sim_fsw_generate_data, fsw, eventlist, filtered_eventlist, trigger_eventlist, finalize_processing=finalize_processing, test_name=test_name, current_time_seconds=current_time_seconds
  ; set default values
  default, finalize_processing, 0
  default, varemask, 'FFFFFFFF'
  default, varpmask, 'FFF'
  default, vardmask, 'FFFFFFFF'
  default, extra_file_ref, test_name + '_' + trim(string(current_time_seconds, format='(I05)'))

  detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1

  trigger_eventlist_counter = n_elements(trigger_eventlist.trigger_events)
  filtered_counts_eventlist_counter = n_elements(filtered_eventlist.detector_events)

  fsw->process, filtered_eventlist, trigger_eventlist, finalize_processing=finalize_processing
  
  
  return 
  ; calculate max integration time for "one time bin" criterion
  dt_integration = ceil(filtered_eventlist.detector_events[-1].relative_time) - floor(filtered_eventlist.detector_events[0].relative_time)

  ; generate the QLTRG (200s integration time)
  ; fixing qltrg to one time bin
  qltrg = stx_fsw_eventlist_accumulator(trigger_eventlist, /livetime, /a2d_only, accumulator='qltrg', /no_prefix, sum_det=0, dt=dt_integration, active_detectors=hw_enabled_detector_mask, /exclude_bad_detectors)

  ; extract all 32 x 12 x 32 accumulator cells for given integration interval
  fsw->getproperty, stx_sim_calibrated_detector_eventlist=calib_events, /combine

  calib_eventlist = stx_construct_sim_calibrated_detector_eventlist(detector_events=calib_events.detector_events, start_time=start_time)

  ; generate the QLACC and transform it to the FPGA format; not affectd by SUMDMASK
  qlacc_32x12x32 = stx_fsw_eventlist_accumulator(calib_eventlist, channel_bin=indgen(33), dt=dt_integration_total, sum_pix=0, sum_det=0, livetime=0, /no_prefix, accumulator='all32x12x32', active_detectors=hw_enabled_detector_mask, /exclude_bad_detectors)

  qlacc_12x32x32 = _transform_32x12x32to12x32x32(qlacc_32x12x32, n_times=n_times)

  ; generate the QLVAR
  varem = _mask2id(_str_hex2byte_mask(varemask))
  vardm = _mask2id(_str_hex2byte_mask(vardmask) and hw_enabled_detector_mask)
  varpm = _mask2id(_str_hex2byte_mask(varpmask, /pixel), /pixel)

  ; hackedy-hack-hack
  ; this takes care of the proper varemask handling in case we have not all energies included
  if(n_elements(varem) ne 32) then begin
    energy_prepped_detector_events = []
    for varem_idx = 0L, n_elements(varem)-1 do begin
      found_idx = where(calib_eventlist.detector_events.energy_science_channel eq varem[varem_idx], count)

      if(count gt 0) then energy_prepped_detector_events = [energy_prepped_detector_events, calib_eventlist.detector_events[found_idx]]
    endfor
    energy_prepped_detector_events = energy_prepped_detector_events[bsort(energy_prepped_detector_events.relative_time)]
    qlvar_input_calib_eventlist = stx_construct_sim_calibrated_detector_eventlist(detector_events=energy_prepped_detector_events, start_time=start_time)
  endif else qlvar_input_calib_eventlist = calib_eventlist

  qlvar = stx_fsw_eventlist_accumulator(qlvar_input_calib_eventlist, channel_bin=indgen(33), sum_pix=1, sum_det=1, livetime=0, accumulator='qlvar', dt=0.1d, det_index_list=vardm, pixel_index_list=varpm, /no_prefix)

  ; writing qlac to binary file, BIG ENDIAN
  qlacc_bin = extra_file_ref + '_qlacc.bin'
  writer = stx_bitstream_writer(size=2L^25, filename=qlacc_bin)

  ; QLACC is forced to one time bin
  ;for nt_i = 0L, 1L-1 do begin
  for p_i = 0L, 12-1 do begin
    for d_i = 0L, 32-1 do begin
      mapped_detector_idx = detector_mapping[d_i]
      for c_i = 0L, 32-1 do begin
        writer->write, qlacc_12x32x32.accumulated_counts[p_i,mapped_detector_idx,c_i,-1], bits=16, debug=debug, silent=silent
      endfor
    endfor
  endfor
  ;endfor
  writer->flushtofile
  destroy, writer

  ; writing qltrg to binary file
  qltrg_bin = extra_file_ref + '_qltrg.bin'
  writer = stx_bitstream_writer(size=2L^25, filename=qltrg_bin)

  ; qltrg is forced to one bin
  ;for nt_i = 0L, 1L-1 do begin
  for trg_i = 0L, 16-1 do begin
    writer->write, qltrg.accumulated_counts[0,0,trg_i,-1], bits=32, debug=debug, silent=silent
  endfor
  ;endfor
  writer->flushtofile
  destroy, writer

  ; writing qlvar to binary file
  qlvar_bin = extra_file_ref + '_qlvar.bin'
  writer = stx_bitstream_writer(size=2L^25, filename=qlvar_bin)
  n_dim = (size(qlvar.accumulated_counts))[0]
  max_loop = n_elements(qlvar.accumulated_counts[0, 0, 0, *]) < 40
  for trg_i = 0, max_loop-1 do begin
    cts = fix(total(qlvar.accumulated_counts[*,0,0,trg_i-max_loop]), type=12)
    writer->write, cts, bits=32, debug=debug, silent=silent
  endfor

  for padding_i = trg_i, 39 do begin
    writer->write, 0, bits=32, debug=debug, silent=silent
  endfor
  writer->flushtofile
  destroy, writer

  ; reading out calibration spectrum to print the counts
  fsw->getproperty, stx_fsw_m_calibration_spectrum=calib_spectrum
  ;calib_spectrum = fsw.calib_spec
  n_calib_counts = total(calib_spectrum.accumulated_counts)

  ; save calibration spectrum for later comparison
  calibration_spectrum_file = extra_file_ref + '_calibration_spectrum.sav'
  save, calib_spectrum, file=calibration_spectrum_file, /compress

  return
end