;---------------------------------------------------------------------------
; Document name: stx_fsw_visibility.pro
; Created by:    Nicky Hochmuth 1.09.2014
;---------------------------------------------------------------------------
;+
; PROJECT:    STIX
;
; NAME:       stx_fsw_visibility
;
; PURPOSE:    stix onboard visibility data structure
;
; CATEGORY:   STIX FSW
;
; CALLING SEQUENCE:
;             
;             STX_VIS = stx_fsw_visibility()
;-

function stx_fsw_visibility
  return, { type       : 'stx_fsw_visibility', $
            total_flux : long64(0), $  ; the total flux
            real_neg   : long64(0), $  ; subtrahend of the real part              
            real_pos   : long64(0), $  ; minuend of the real part 
            imag_neg   : long64(0), $  ; subtrahend of the imaginary part 
            imag_pos   : long64(0), $   ; minuend of the imaginary part
            real_part  : long64(0), $
            imag_part  : long64(0), $
            sigamp  : long64(0), $
            detector_id : byte(0) $
          }
end
