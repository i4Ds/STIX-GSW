;---------------------------------------------------------------------------
; Document name: stx_ivs_get_flare_magnitude_index.pro
; Created by:    Nicky Hochmuth, 2013/07/24
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       Determine a ‘total flare magnitude index’, FMtot, to be used as an index for determining
;       the division between thermal and non-thermal energies. The flare magnitude index is
;       determined by a set of thresholds for Ntot in a TC-specified table. FMtot may have
;       values from 0 to 23. (This corresponds roughly to steps of x2 in Ntot.)
;
; CATEGORY:
;       Stix on Bord Algorithm
;
; CALLING SEQUENCE:
;       magnitude = stx_ivs_get_flare_magnitude_index(total_count,range="total")
;
; HISTORY:
;       2013/07/24, Nicky.Hochmuth@fhnw.ch, initial release
;       2014/03/21 Nicky Hochmuth: get default lut from keywords
;-
;+
; :description:
;     Determine a ‘total flare magnitude index’, FMtot, to be used as an index for determining
;     the division between thermal and non-thermal energies. The flare magnitude index is
;     determined by a set of thresholds for Ntot in a TC-specified table. FMtot may have
;     values from 0 to 23. (This corresponds roughly to steps of x2 in Ntot.)
;       
; :params:
;    Ntot; the total number of counts in the flare
;    
; :keywords:    
;    range:                                 in, optional, type="string [total|thermal|nonthermal]", default="total"
;    
;    total_flare_magnitude_index_lut:       optional, in, type="ulong(24)" 
;                                           the upper limit of counts for each total magnitude index
;    
;    thermal_flare_magnitude_index_lut:     optional, in, type="ulong(24)" 
;                                           the upper limit of counts for each thermal magnitude index
;    
;    nonthermal_flare_magnitude_index_lut:  optional, in, type="ulong(24)" 
;                                           the upper limit of counts for each nonthermal magnitude index
;-
function stx_ivs_get_flare_magnitude_index, Ntot, $
  range                                 = range, $ 
  total_flare_magnitude_index_lut       = total_flare_magnitude_index_lut, $
  thermal_flare_magnitude_index_lut     = thermal_flare_magnitude_index_lut, $
  nonthermal_flare_magnitude_index_lut  = nonthermal_flare_magnitude_index_lut
  
  
  default, range, 'total'
  
  case (STRLOWCASE(string(range))) of
    "total":      begin
                    default, total_flare_magnitude_index_lut, 2000L* (ulong64(2)^indgen(24))
                    lut = total_flare_magnitude_index_lut
                    end
    "thermal":    begin
                    default, thermal_flare_magnitude_index_lut, 1000L*(ulong64(2)^indgen(24))
                    lut = thermal_flare_magnitude_index_lut
                  end
    "nonthermal": begin
                    default, nonthermal_flare_magnitude_index_lut, 100L*(ulong64(2)^indgen(24))
                    lut = nonthermal_flare_magnitude_index_lut
                  end
    else:         begin
                    default, total_flare_magnitude_index_lut, 2000L* (ulong64(2)^indgen(24))
                    lut = total_flare_magnitude_index_lut
                  end
  endcase
  
  return, value_locate(lut,Ntot)+1 < 23
end