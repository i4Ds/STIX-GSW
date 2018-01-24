; -----------------------------------------------------------------------------
;+
; :description:
;     Functin creates the string (raw of text table) based on stx_sim_source structure. 
;     This string can be use e.g. to save the data to the text file.
;     Structure is defined by the procedure STX_SIM_SOURCE_STRUCTURE.pro
;
; :params:
;     str : in, required, type = "stx_sim_source structure"
;           Structure containing parameters that define simulated sources.
;           Structure is defined by the procedure STX_SIM_SOURCE_STRUCTURE.pro
;    
; :returns:
;     One line string containing all relevant informations from the input source structure
;      
; :keywords:
;     none
;
; modification history:
;     28 Oct 2012 - Marek Steslicki (Wro), written
;     10-Feb-2013 - Marek Steslicki (Wro), output format change
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to use new tag
;                   names defined during merging with STX_SIM_FLARE.pro
;     01-Nov-2013 - Shaun Bloomfield (TCD), 'type' tag changed to
;                   'shape' and 'name' tag changed to 'source'
;-
function stx_sim_sourcestructure2string, str
  case str.shape of
     "point":     begin
                     return, string( format='(I3, " point     ", F10.1, F10.1, F10.1, F15.0, F10.1)', $
                                     str.source, str.xcen, str.ycen, str.duration, str.flux, str.distance )
                  end
     "gaussian":  begin
                     return, string( format='(I3, " gaussian  ", F10.1, F10.1, F10.1, F15.0, F10.1,'+$
                                     'F10.1, F10.1, F10.1)', $
                                     str.source, str.xcen, str.ycen, str.duration, str.flux, str.distance, $
                                     str.fwhm_wd, str.fwhm_ht, str.phi )
                  end
     "loop-like": begin
                     return, string( format='(I3, " loop-like ", F10.1, F10.1, F10.1, F15.0, F10.1,'+$
                                     'F10.1, F10.1, F10.1, F10.1)', $
                                     str.source, str.xcen, str.ycen, str.duration, str.flux, str.distance, $
                                     str.fwhm_wd, str.fwhm_ht, str.phi, str.loop_ht )
                  end
     else:        begin
                     return, string( format='(I3, " unknown   ", F10.1, F10.1, F10.1, F15.0, F10.1,'+$
                                     'F10.1, F10.1, F10.1)', $
                                     str.source, str.xcen, str.ycen, str.duration, str.flux, str.distance, $
                                     str.fwhm_wd, str.fwhm_ht, str.phi )
                  end
  endcase
end
