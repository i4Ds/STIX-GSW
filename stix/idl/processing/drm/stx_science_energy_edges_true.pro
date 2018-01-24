;+
; :Description:
;    stx_science_energy_edges_true is a function that returns the true science channel edges
;    in keV as a function of pixel_number (0-11) and detector_number (1-32)
; :Examples:
;    IDL> print, stx_science_energy_edges_true( 5, 8 )
;          4.03956      5.01295      5.98634      6.95973      8.03046      9.00385      9.97724      11.0480      12.0214      12.9947      13.9681
;          15.0389      16.0122      17.9590      20.0031      22.0473      24.9674      27.9849      31.9758      35.9667      39.9576      45.0192
;          49.9835      55.0451      60.0094      64.9737      70.0353      74.9996      85.0255      100.016      115.006      129.996      150.048
;    IDL> ee =  stx_science_energy_edges_true( /all )
;    IDL> print, ee[ *, 5, 7]
;          4.03956      5.01295      5.98634      6.95973      8.03046      9.00385      9.97724      11.0480      12.0214      12.9947      13.9681
;          15.0389      16.0122      17.9590      20.0031      22.0473      24.9674      27.9849      31.9758      35.9667      39.9576      45.0192
;          49.9835      55.0451      60.0094      64.9737      70.0353      74.9996      85.0255      100.016      115.006      129.996      150.048
;    IDL> help, stx_science_energy_edges_true( /all )
;    <Expression>    FLOAT     = Array[33, 12, 32]
;    IDL> help, stx_science_energy_edges_true( 5, 8 )
;    <Expression>    FLOAT     = Array[33]
; 
; :Params:
;    pixel_number - single pixel number from 0-11 for a single caliste specified by the
;     detector_number
;    detector_number - stix caliste detector number 1-32
;
; :Keywords:
;    all - if set, return all the edges for all 384 pixel-detector combinations
;    offset_gain - structure of type 'stx_offset_gain' for all 384 detector pixel combinations, optional
;    science_energy_edges - 33 science energy (keV) edges, optional, uses default reader otherwise 
;    
;
; :Author: richard.schwartz@nasa.gov
; :History: 3-jul-2015. Initial version
;-
function stx_science_energy_edges_true, pixel_number, detector_number, $
  offset_gain = offset_gain, $
  science_energy_edges = science_energy_edges, $
   all = all

default, detector_number, 1
default, pixel_number, 0
default, all, 0 ;if set, then return all edges 33 x 12 x 32
;if the offset_gain structure has been input, use it, otherwise get it
offset_gain = is_struct( offset_gain ) ? offset_gain : $
  reform( stx_offset_gain_reader( ), 12, 32 ) ;whole structure

;if the science_energy_edges have been input, use them, otherwise get them
science_edg = exist( science_energy_edges ) ? science_energy_edges : stx_science_energy_channels(/edges_1) 

offset_gain = all ? offset_gain : offset_gain[ pixel_number, detector_number - 1]
gain = offset_gain.gain
offset = offset_gain.offset
offset = ~all ? offset : make_array( 33, val=1.0)  # offset[*]

rounded = ~all ? round( science_edg / gain  + offset ) : $
  round( science_edg # ( 1.0 / gain[*] )  + offset  )
true_edg =  ~all ? ( rounded - offset ) * gain : $
   reform( ( rounded - offset ) * ( make_array( 33, val=1.0)  # gain[*] ), 33, 12, 32)
return, true_edg
end