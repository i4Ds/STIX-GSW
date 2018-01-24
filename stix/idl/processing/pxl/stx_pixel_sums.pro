;---------------------------------------------------------------------------
; Document name: stx_pixel_sums.pro
; Created by:    richard.schwartz 22.07.2013
;---------------------------------------------------------------------------
;+
; PROJECT:    STIX
;
; NAME:       stx_pixel_sums
;
; PURPOSE:    Sums the pixels of a detector to 4 remaining virtual pixels 
;             is applied for all times, energies and detectors
;
; CATEGORY:   STIX imaging
;
; CALLING SEQUENCE:
;             
;             STX_PIXEL_DATA = stx_pixel_sums(pixel_data, sumcase)
;
; HISTORY:
;       
;       22.07.2013 richard schwartz, replacement for stx_pixel_summaries with
;         modernized summations using reform and total. This version will be simpler
;         to implement when we can no longer have 4 d pixel data arrays. Ultimately they must be 3 d,
;         one for the cell index, one for the detector, one for the pixel. The cell index has unique time bin
;         and energy bin identifiers. Not an array of time and energy cells
;-

;+
; :description:
;    Sums each detector pixel columns to 4 virtual pixels
;
; :params:
;    pixel_data     : the input data
;    sumcase        : integration method
;                      0: 'Pixel sum over two big pixels'
;                      1: 'Pixel sum over two big pixels and small pixel'
;                      2: 'Only upper row pixels'
;                      3: 'Only lower row pixels'
;                      4: 'Only small pixels'
;
; returns a new stx_pixel_data with virtual pixels
;-
function stx_pixel_sums, pixel_data, sumcase, fsw=fsw
  case sumcase of
    0: begin
      indices = [0, 1]
      info = 'Sum counts over two big pixels'
    end
    1: begin
      indices = indgen(3)
      info = 'Sum counts over two big pixels and small pixel'
    end
    2: begin
      indices = [0]
      info = 'Only upper row pixels'
    end
    3: begin
      indices = [1]
      info = 'Only lower row pixels'
    end
    4: begin
      indices = [2]
      info = 'Only small pixels'
    end
  endcase
  
  n_inputs = n_elements(pixel_data)
  
  if keyword_set(fsw) then begin
    pxl_data_summed = replicate(stx_fsw_pixel_data_summed(),n_inputs)
    pxl_data_summed.relative_time_range = pixel_data.relative_time_range
    pxl_data_summed.energy_science_channel_range = pixel_data.energy_science_channel_range
    pxl_data_summed.sumcase = sumcase
  endif else begin
    pxl_data_summed = replicate(stx_pixel_data_summed(),n_inputs)
    pxl_data_summed.time_range = pixel_data.time_range
    pxl_data_summed.energy_range = pixel_data.energy_range
    pxl_data_summed.sumcase = sumcase
    pxl_data_summed.live_time = pixel_data.live_time
  end  
  
  n_det = (size(pixel_data.counts, /dim))[1]
   
  ; group by time-energy-detector and pixel row, Ncells x 4 x 3 x inputs
  pixels = reform(pixel_data.counts, 4, 3, n_det, n_inputs)
  summed_pixels = n_elements( indices ) eq 1 ? reform(pixels[*, indices , * ,*]) : total( pixels[*, indices, *, * ], 2 )
    
  pxl_data_summed.counts = summed_pixels
  

  return, pxl_data_summed
end