;+
;
; NAME:
;
;   stx_subc_transmission
;
; PURPOSE:
;
;   Compute the trasmission of a STIX subcollimator corrected for internal shadowing
;
; CALLING SEQUENCE:
;
;   subc_transmission = stx_subc_transmission(flare_loc)
;
; INPUTS:
;
;   flare_loc: bidimensional array containing the X and Y coordinate of the flare location 
;             (arcsec, in the STIX coordinate frame)
;
; OUTPUTS:
;
;   A float number that represent the subcollimator transmission value
;
; HISTORY: August 2022, Massa P., first version (working only for detectors 3 to 10)
;
; CONTACT:
;   paolo.massa@wku.edu
;-


function stx_subc_transmission, flare_loc

restore,loc_file( 'grid_temp.sav', path = getenv('STX_GRID') )
fff=read_ascii(loc_file( 'grid_param_front.txt', path = getenv('STX_GRID') ),temp=grid_temp)
rrr=read_ascii(loc_file( 'grid_param_rear.txt', path = getenv('STX_GRID') ),temp=grid_temp)

grid_orient_front = 180.-fff.o ;; Orientation of the slits of the grid as seen from the detector side
grid_pitch_front  = fff.p
grid_slit_front   = fff.slit
grid_thick_front  = fff.thick

grid_orient_rear = 180.-rrr.o ;; Orientation of the slits of the grid as seen from the detector side
grid_pitch_rear  = rrr.p
grid_slit_rear   = rrr.slit
grid_thick_rear  = rrr.thick

transm = fltarr(32)
sc = fff.sc

for i=0,n_elements(grid_orient_front)-1 do begin
  
  ;; Exclude detectors 1 and 2
  
  if (sc[i] ne 11) and (sc[i] ne 12) and (sc[i] ne 13) and (sc[i] ne 17) and (sc[i] ne 18) and (sc[i] ne 19) then begin
   
   transm_front = stx_grid_transmission(flare_loc[0], flare_loc[1], grid_orient_front[i], $
                                      grid_pitch_front[i], grid_slit_front[i], grid_thick_front[i])
   transm_rear  = stx_grid_transmission(flare_loc[0], flare_loc[1], grid_orient_rear[i], $
                                      grid_pitch_rear[i], grid_slit_rear[i], grid_thick_rear[i])
   transm[sc[i]-1] = transm_front * transm_rear
    
  endif
  
endfor

transm[where(transm eq 0.)] = 1

return, transm

end