;---------------------------------------------------------------------------
; Document name: stx_fsw_vis_image.pro
; Created by:    Nicky Hochmuth 1.09.2014
;---------------------------------------------------------------------------
;+
; PROJECT:    STIX
;
; NAME:       stx_fsw_vis_image
;
; PURPOSE:    stix onboard visibility container to bundle all visibility for a time / energy interval
;
; CATEGORY:   STIX FSW
;
; CALLING SEQUENCE:
;             
;             STX_VIS = stx_fsw_vis_image()
;-

function stx_fsw_vis_image, n_detectors=n_detectors
  default, n_detectors, 32
  return, { type                          : 'stx_fsw_vis_image', $
            relative_time_range           : dblarr(2), $ ; relative start and end time of integration in seconds
            energy_science_channel_range  : bytarr(2), $ ; [0,31]
            total_flux                    : ulong64(0), $
            vis                           : replicate(stx_fsw_visibility(), n_detectors) $ ; one visibiliy per detector
          }
end