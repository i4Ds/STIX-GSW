;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_data_level2label
;
; :description:
;    This function takes the numeric value of a STIX onboard data product compression 
;    level and returns its name as a string.
;
; :categories:
;    utilities 
;
; :params:
;    data_level : in, required, type="int"
;             the numerical value of the STIX data compression level 
;
; :returns:
;    String with name of onboard data product.
;
; :examples:
;   IDL> stx_data_level2label(1)
;        Pixel Data
;   IDL> level = stx_data_level2label(4)
;   IDL> print, level
;   Spectrogram 
;   
; :history:
;    26-Aug-2022 - ECMD (Graz), initial release
;
;-
function stx_data_level2label, data_level

  case data_level of
    0 : label = 'Raw Pixel Data'
    1 : label = 'Pixel Data'
    2 : label = 'Summed Pixel Data'
    3 : label = 'Visibility'
    4 : label = 'Spectrogram'
    else: message, 'Unregonised data level.'
  endcase

  return, label
end