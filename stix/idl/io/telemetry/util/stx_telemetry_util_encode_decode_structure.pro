;+
;
; 
;
;-
function _prepare_output_format, value, destination, tag
  if(isvalid(tag) and is_struct(destination)) then begin
    destination.(tag_index(destination, tag)) = value
    return, destination
  endif else return, value
end

pro stx_telemetry_util_encode_decode_structure, input=input, output=output, ni_wi_li=ni_wi_li, $
  detector_pixel_subspectrum_address=detector_pixel_subspectrum_address, pixel_mask=pixel_mask, $
  detector_mask=detector_mask, subspectrum_mask=subspectrum_mask, tag=tag, number_energy_bins=number_energy_bins,$
  energy_bin_mask=energy_bin_mask, flare_message=flare_message, fdir_status_mask=fdir_status_mask
  if(~isvalid(input)) then begin
    ; encode
    ; --------

    ; li, wi, and ni
    ; Li: 0 - 1023
    ; Wi: 1 - 1024 (saved as 0 - 1023)
    ; Ni: 1 - 1024 (saved as 0 - 1023)
    if(isvalid(ni_wi_li)) then begin
      niwili = ulong(ni_wi_li)
      if(niwili[0] lt 1 or niwili[0] gt 1024) then message, 'Ni must be between 1 and 1024'
      if(niwili[1] lt 1 or niwili[1] gt 1024) then message, 'Wi must be between 1 and 1024'
      if(niwili[0] * niwili[1] gt 1024) then message, 'Wi * Ni must not be greater than 1024'
      if(niwili[2] lt 0 or niwili[2] gt 1023) then message, 'Li must be between 0 and 1023'
      if(niwili[0] * niwili[1] + niwili[2] gt 1024) then message, 'Li + Wi * Ni must not be greater than 1024'
      out = ishft(niwili[0] - 1, 20) or ishft(niwili[1] - 1, 10) or (niwili[2])
    endif else $

      ; detectors[0-31], pixel[0-11], subspectrum[0-7]
      ; ESC: detectors[1-31]!
      ; pixel, detector, and spectrum definition id
      if(isvalid(detector_pixel_subspectrum_address)) then begin
      dps = ulong(detector_pixel_subspectrum_address)
      out = ishft(dps[0], 7) or ishft(dps[1], 3) or dps[2]
      out = [ishft(out, -8), out and 2^8-1]
    endif else $

      ; pixel mask
      ; order: [11, 10, 9, ..., 3, 2, 1, 0]
      if(isvalid(pixel_mask)) then begin
      out = total(2UL^(where(reverse(pixel_mask) eq 1)), /preserve_type)
    endif else $

      ; detector mask
      ; order: [31, 30, 29, ..., 3, 2, 1, 0]
      if(isvalid(detector_mask)) then begin
      out = total(2UL^(where(reverse(detector_mask) eq 1)), /preserve_type)
    endif else $
      
      ; energy bin mask
      ; order: [32, 31, ..., 3, 2, 1, 0]
      ; number_energy_bins (E): Probably more or less than 5 energy bins
      if(isvalid(energy_bin_mask)) then begin
      out = total(2ULL^(where(reverse(energy_bin_mask) eq 1)), /preserve_type)
      number_energy_bins = total(energy_bin_mask)-1
    endif else $    
      
      ; FDIR status mask
      ; order: [31, ..., 3, 2, 1, 0]
      if(isvalid(fdir_status_mask)) then begin
      out = total(2UL^(where(reverse(energy_bin_mask) eq 1)), /preserve_type)
      fdir_status_mask = total(fdir_status_mask)-1
    endif else $      
      
      ; flare message
      ; order: [7, 6, ..., 3, 2, 1, 0]
      if(isvalid(flare_message)) then begin
      out = total(2B^(where(reverse(flare_message) eq 1)), /preserve_type)
    endif else $ 
        
      ; subspectrum mask
      if(isvalid(subspectrum_mask)) then begin
      out = total(2^where(subspectrum_mask eq 1), /preserve_type)        
    endif else begin
      message, 'Could not determine what to encode'
    endelse

    output = _prepare_output_format(out, output, tag)

    ;if(isvalid(tag) and is_struct(output)) then output.(tag_index(output, tag)) = out $
    ;else output = out

  endif else begin
    ; decode
    ;--------

    ; li, wi, and ni
    ; Li: 0 - 1023
    ; Wi: 1 - 1024 (saved as 0 - 1023)
    ; Ni: 1 - 1024 (saved as 0 - 1023)
    if(arg_present(ni_wi_li)) then begin
      ni = ishft(input, -20) and 2UL^20-1
      wi = ishft(input, -10) and 2UL^10-1
      li = input and 2UL^10-1

      ni_wi_li = _prepare_output_format([ni + 1, wi + 1, li], output, tag)
    endif else $

      ; detectors[0-31], pixel[0-11], subspectrum[0-7]
      ; ESC: detectors[1-31]!
      ; detector pixel and spectrum id address
      if(arg_present(detector_pixel_subspectrum_address)) then begin
      if(n_elements(input) eq 2) then in = ishft(ulong(input[0]), 8) or ulong(input[1]) $
      else in = ulong(input)

      detector = ishft(in, -7)
      pixel = ishft(in, -3) and 2UL^4-1
      subspectrum = in and 2UL^3-1
      detector_pixel_subspectrum_address = _prepare_output_format([detector, pixel, subspectrum], output, tag)
    endif else $

      ; pixel mask
      ; order: [11, 10, 9, ..., 3, 2, 1, 0]
      if(arg_present(pixel_mask)) then begin
      pixel_mask = _prepare_output_format((2UL^(11 - lindgen(12)) and input) gt 0, output, tag)
    endif else $

      ; detector mask
      ; order: [31, 30, 29, ..., 3, 2, 1, 0]
      if(arg_present(detector_mask)) then begin
      detector_mask = _prepare_output_format((2UL^(31 - lindgen(32)) and input) gt 0, output, tag)
    endif else $

      ; energy_bin mask
      ; order: [32, 31, 30, ..., 3, 2, 1, 0]
      ; number_energy_bins (E): Probably more or less than 5 energy bins
      if(arg_present(energy_bin_mask)) then begin
      energy_bin_mask = _prepare_output_format((2ULL^(32 - lindgen(33)) and input) gt 0, output, tag)
      number_energy_bins = total(energy_bin_mask)-1
    endif else $

      ; FDIR status mask
      ; order: [31, 30, 29, ..., 3, 2, 1, 0]
      if(arg_present(fdir_status_mask)) then begin
      fdir_status_mask = _prepare_output_format((2UL^(31 - lindgen(32)) and input) gt 0, output, tag)
    endif else $
            
      ; flare message
      ; order: [7, 6, ..., 3, 2, 1, 0]
      if(arg_present(flare_message)) then begin
      flare_message = _prepare_output_format((2B^(bindgen(8)) and input) gt 0, output, tag)
    endif else $
      
      ; subspectrum mask
      if(arg_present(subspectrum_mask)) then begin
      subspectrum_mask = _prepare_output_format((2^(lindgen(8)) and input) gt 0, output, tag)
    endif else $

      message, 'Could not determine what to decode'

  endelse
end