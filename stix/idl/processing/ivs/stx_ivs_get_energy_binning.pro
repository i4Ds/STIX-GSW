;---------------------------------------------------------------------------
; Document name: stx_ivs_get_energy_binning.pro
; Created by:    Nicky Hochmuth, 2013/07/24
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Use the flare magnitude index as an index to a 24-element TC-specified lookup table to
;       determine the minimum science channel number to be considered as ‘nonthermal’.
;       Channels below this value are considered themal’.
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       binning = stx_ivs_get_energy_binning(magnitude,/thermal)
;
; HISTORY:
;       2013/07/24, Nicky.Hochmuth@fhnw.ch, initial release
;       
; TODO:
;       2013/07/24 Nicky Hochmuth: get default lut from dbase
;-
;+
; :description:
;     Use a TC-populated lookup table indexed by FMt to identify a set of Mt
;     contiguous image energy bands (each consisting of one or more contiguous science energy channels
;     science energy bins (denoted as imaging thermal energy bins, Eti, i = 0,,,Mt-1. Do the
;     same using a different TC-specified lookup table to identify a corresponding set of Mnt
;     contiguous image energy bins. (Figure 2). The output of step 2 is then two set of ‘energy bins’, 
;     one thermal and one nonthermal, and each of which corresponds to one or
;     more science energy bins. 
;       
; :params:
;    the magnitude index for the band
;     
; :keywords:
;    thermal: determines whether thermal or nonthermal band
;     
;-
function stx_ivs_get_energy_binning, flare_magnitude_index, thermal, energy_binning_lut = energy_binning_lut

  default, thermal, 1
  
  thermal = thermal > 0 < 1
  flare_magnitude_index = flare_magnitude_index > 0 < 23
  
   if ppl_typeof(energy_binning_lut,compareto="stx_ivs_energy_binning_lut") then begin
    idx = where(energy_binning_lut.THERMAL eq thermal AND energy_binning_lut.FLARE_MAGNITUDE eq flare_magnitude_index)
    return,  [transpose(energy_binning_lut.START_E[idx]),transpose(energy_binning_lut.END_E[idx])]
  endif else begin
  
    if thermal then begin
      switch (flare_magnitude_index) of
        0: 
        1:
        2:
        3:
        4:
        5: return, [transpose(indgen(4)*8),transpose(indgen(4)*8)+8]  
        
        6: 
        7:
        8:
        9:
        10:
        11: return, [transpose(indgen(8)*4),transpose(indgen(8)*4)+4]
        
        12: 
        13:
        14:
        15:
        16:
        17: return, [transpose(indgen(16)*2),transpose(indgen(16)*2)+2]
        
        18: 
        19:
        20:
        21:
        22:
        23: 
        else: return, [transpose(indgen(32)),transpose(indgen(32))+1]
      endswitch
    endif else begin
        switch (flare_magnitude_index) of
        0: 
        1:
        2:
        3:
        4:
        5: return, [transpose(indgen(4)*8),transpose(indgen(4)*8)+8]  
        
        6: 
        7:
        8:
        9:
        10:
        11: return, [transpose(indgen(8)*4),transpose(indgen(8)*4)+4]
        
        12: 
        13:
        14:
        15:
        16:
        17: return, [transpose(indgen(16)*2),transpose(indgen(16)*2)+2]
        
        18: 
        19:
        20:
        21:
        22:
        23: 
        else: return, [transpose(indgen(32)),transpose(indgen(32))+1]
      endswitch
    endelse
  endelse
end