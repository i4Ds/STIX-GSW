;---------------------------------------------------------------------------
; Document name: stx_pixel_summaries.pro
; Created by:    nicky.hochmuth 29.08.2012
;---------------------------------------------------------------------------
;+
; PROJECT:    STIX
;
; NAME:       stx_pixel_summaries
;
; PURPOSE:    Sums the pixels of a detector to 4 remaining virtual pixels 
;             is applied for all times, energies and detectors
;
; CATEGORY:   STIX imaging
;
; CALLING SEQUENCE:
;             
;             STX_PIXEL_DATA = stx_pixel_summaries(STX_PIXEL_DATA, SumCase)
;
; HISTORY:
;       29.08.2012 nicky.hochmuth initial release
;       22.07.2013 richard schwartz, cleaned the documentation header
;         changed the name sumtype to SumCase as that's the name in the config manager
;         I'm not too enthusiastic about stx_pixel_summaries as the name of this routine
;         A better name might be stx_pixel_sums. I also find the use of loops here
;         to be unnecessary and in fact they hide the sums. I'm writing a better method
;         in a new version to be called stx_pixel_sums with the same inputs
;-

;+
; :description:
;    Sums each detector pixel columns to 4 virtual pixels
;
; :params:
;    stx_pixel_data : the input data
;    sumcase        : integration method
;                      0: 'Pixel sum over two big pixels'
;                      1: 'Pixel sum over two big pixels and small pixel'
;                      2: 'Only upper row pixels'
;                      3: 'Only lower row pixels'
;                      4: 'Only small pixels'
;
; returns a new stx_pixel_data with virtual pixels
;-
function stx_pixel_summaries, stx_pixel_data, sumcase
help, sumcase
  dim = size(stx_pixel_data.data)
  
  ebs  =  dim[2]	; energy bins
  dts  =  dim[3]	; number of detectors
  pxls = 	dim[4]	; number of pixels
  tnums=  dim[1]  ; time bins
  
  
  interim_array = stx_pixel_data.data
  
  sum_array = dblarr(tnums,ebs,dts,4)
  
  for tim_i=0,tnums-1 do begin  ; time-loop               ;tim_i = tindex[t_i]
  
    for energy_i=0,ebs-1 do begin  ; energy bins-loop        ;energy_i = eindex[e_i]
    
      for detect_i=0,dts-1 do begin  ; detector-loop
      
        inter_arr = interim_array[tim_i,energy_i,detect_i,*]
        for i=0,3 do begin
        
          case sumcase of
            0: begin  
              sum_array[tim_i,energy_i,detect_i,i] = inter_arr[i]+inter_arr[i+4]
              info = 'Pixel summary over two big pixels'
            end
            1: begin
              sum_array[tim_i,energy_i,detect_i,i] = inter_arr[i]+inter_arr[i+4]+inter_arr[i+8]
              info = 'Pixel summary over two big pixels and small pixel'
            end
            2: begin
              sum_array[tim_i,energy_i,detect_i,i] = inter_arr[i]
              info = 'Only upper row pixels'
            end
            3: begin
              sum_array[tim_i,energy_i,detect_i,i] = inter_arr[i+4]
              info = 'Only lower row pixels'
            end
            4: begin
              sum_array[tim_i,energy_i,detect_i,i] = inter_arr[i+8]
              info = 'Only small pixels'
            end
          endcase
        endfor
      endfor  ; detector-loop
    endfor  ; energy bins-loop
  endfor  ; time-loop

  print, info

  return, stx_pixel_data(data=sum_array,eaxis=stx_pixel_data.eaxis, ltime=stx_pixel_data.ltime, taxis=stx_pixel_data.taxis)
end