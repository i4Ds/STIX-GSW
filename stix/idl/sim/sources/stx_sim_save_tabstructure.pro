;+
; :description:
;     This procedure saves the array of structers, which contains parameters 
;     of simulated sources, into text file.
;
; :params:
;     allelementsstructure : in, required, type = "array of stx_sim_source structures"
;                            array of structures containing parameters that define simulated sources.
;                            structures are defined by the procedure STX_SIM_SOURCE_STRUCTURE.pro
;                            
;     filename             : in, required, type = "string"
;                            name of output text file
; 
; :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     10-Feb-2013 - Marek Steslicki (Wro), size and position units
;                   changed to arcseconds
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to use new tag
;                   names defined during merging with STX_SIM_FLARE.pro
;     23-Oct-2013 - Shaun Bloomfield (TCD), source flux, position and
;                   geometry defined as that being viewed from 1 AU
;     01-Nov-2013 - Shaun Bloomfield (TCD), 'type' tag changed to
;                   'shape'
;-
pro stx_sim_save_tabstructure, allelementsstructure, filename
      n=n_elements(allelementsstructure)
      close,1
      openw,1, filename
      ;  header
      printf,1,'# 1     2         3         4          5            6           7         8         9        10        11     '
      printf,1,'#                                                                                                             '
      printf,1,'#No.  Source    Position  Position  Duration       Flux       Source    Width    Height      CCW      Loop    '
      printf,1,'#     Shape        X         Y                  of photons   Distance   FWHM      FWHM      Source   Height   '
      printf,1,'#               at 1 AU   at 1 AU                at 1 AU               at 1 AU   at 1 AU   Rotation  at 1 AU  '
      printf,1,'#               [arcsec]  [arcsec]    [s]       [ph/cm^2/s]    [AU]    [arcsec]  [arcsec]  [degree]  [arcsec] '
      printf,1,'#                                                                                                             '
      printf,1,'##############################################################################################################'
;     printf,1,'-I3----------A-----F10.1-----F10.1-----F10.1----------F15.0-----F10.1-----F10.1-----F10.1-----F10.1-----F10.1'
;  Check for string matchup in output file
;  '-' pads to left of print format designation to indicate space used
;  i.e., columns are right-aligned to right edge of format designation
      ;  data
      for i=0,n-1 do begin
        printf, 1, stx_sim_sourcestructure2string(allelementsstructure[i])
      endfor
      close,1
end
