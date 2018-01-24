;+
; :description:
;    This function calculates the photon material path length through
;    the front or rear grid plane for a given STIX subcollimator.
;
; :params:
;    pos:     in, required, type="float"
;             [n, 2]-element array containing the [n, [X, Y]]
;             locations of n photons in the STIX front (default) or
;             rear (optional flag) grid plane, measured in mm
;             relative to the STIX optical axis.
;
;    angle:   in, required, type="float"
;             n-element vector containing the photon trajectory tilt
;             angles for n photons, measured in degrees relative to
;             the STIX optical axis.
;
;    subc:    in, required, type="structure"
;             single-element subcollimator geometry structure.
;
; :keywords:
;    rear:  in, optional, type="bool", default="empty/false"
;           if set, this function calculates the photon material path
;           length for the STIX rear grid plane.
;
;    open:  in, optional, type="bool", default="empty/false"
;           if set, this function ignores slat obscuration in the 
;           front and rear grids (i.e., allows for testing of the
;           full illumination of the subcollimator active areas).
;
; :returns:
;    Material path length of photon trajectory in mm.
;
; :errors:
;
;
; :history:
;    21-Aug-2012 - Shaun Bloomfield (TCD), created routine
;    20-Nov-2012 - Shaun Bloomfield (TCD), implemented final angle 
;                    conventions
;    20-Dec-2012 - Shaun Bloomfield (TCD), fixed CFL transmission test
;    14-Jan-2013 - Shaun Bloomfield (TCD), new keyword default logic, 
;                    use of lowercase subcollimator labels, and moved 
;                    transmission test to stx_sim_periodic_tran.pro 
;                    (since called twice with grid bridge inclusion)
;    30-Apr-2013 - Shaun Bloomfield (TCD), vectorized photon handling
;    05-Nov-2013 - Shaun Bloomfield (TCD), transmission probability
;                    changed to material path length
;    23-Apr-2014 - ECMD (GRAZ), changed grid thickness to 400 microns
;                  (0.4 mm)    
;    28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;                  and areas to cm^2
;    12-Nov-2014 - Shaun Bloomfield (TCD), modified to pass in grid 
;                  thickness and not tilt angle of photon path
;    09-Dec-2015 - Richard Schwartz (GSFC), grid_thick now should have to
;                  be defined for pos and if it is sets path_length to grid_thick 
;                  Also, some minor changes to array creation and the final
;                  compute of path_length, separate combined xy vector input pos
;                  into xpos and ypos for a small increase in performance
;    
; :todo:
;    30-Apr-2013 - Shaun Bloomfield (TCD), move 'bkg' subcollimator
;                  transmission to a subroutine function and call
;                  aperture geometry from a parameter look-up file
;-
function stx_sim_grid_tran, xpos, ypos, grid_thick, subc, $
                            rear=rear, open=open
  ;clock = tic('start')
  ;  Set optional keyword defaults
  rear = keyword_set(rear)
  open = keyword_set(open)
  
  ;  Extract relevant front or rear grid characteristics
  grid = rear ? subc.rear : subc.front
  
  ;  Determine total number of photon locations
  n_pos = ( size( xpos, /dimension ) )[0] ;n_elements( pos[*, 0] )
  
  ;  Initiate output array of photon material path lengths, default
  ;  to all photons passing through material
  ;path_len = dblarr(n_pos) + grid_thick ;changed RAS, 9-dec-2015
  path_len = n_elements( grid_thick ) ne n_pos ? dblarr(n_pos) + grid_thick :grid_thick
  
  case 1 of 
     ;  For testing purposes, ignore possible grid slat obscuration
     open : path_len[*] = 0.
     
     ;  Photons fall in the completely open front grid area of the 
     ;  background flux monitor
     strlowcase(subc.label) eq 'bkg' and ~rear : path_len[*] = 0.
     
     ;  Photons fall in the obscured rear grid area of the background 
     ;  flux monitor
     strlowcase(subc.label) eq 'bkg' and rear : begin
        
        ;  Initiate separate arrays for tracking circular/rectangular 
        ;  aperture transmission
        cir_tran = bytarr( n_pos ) ;byte(path_len)*0b
        rec_tran = cir_tran        ;byte(path_len)*0b
        
        ;  Determine photon locations relative to centre of grid 
        rel_xpos = xpos - grid.x_cen 
        rel_ypos = ypos - grid.y_cen 
  
;        ;  TODO: 
;        bkg_aper = stx_read_bkg_aper( )
;        containing bkg_aper.circ.centre
;                   bkg_aper.circ.radius
;                   bkg_aper.rect.left
;                   bkg_aper.rect.right
;                   bkg_aper.rect.bottom
;                   bkg_aper.rect.top
        
        ;  Define X & Y centroids of 8 circular apertures (in mm)
        ;  - 2D array of [2, 8] locations, where 2 refers to X and Y
        circ_cen = [ [-4.0,  3.7], [-4.0,  2.1], $
                     [-1.4,  2.9], [ 1.4,  2.9], $
                     [-1.4, -2.9], [ 1.4, -2.9], $
                     [ 4.0, -2.1], [ 4.0, -3.7] ]
        
        ;  Define radii of 8 circular apertures (in mm)
        circ_rad = [ 0.250d, 0.250d, 0.056d, 0.180d, $
                     0.180d, 0.056d, 0.250d, 0.250d ]
        
        ;  Check photon location against radius of 8 circular apertures
        for i=0, 7 do $
           cir_tran += ( sqrt( ( ( rel_xpos - circ_cen[0, i] )^(2.d) ) + $
                               ( ( rel_ypos - circ_cen[1, i] )^(2.d) ) ) lt circ_rad[i] )
        
        ;  Define X edges of 2 rectangular apertures (in mm) 
        ;  - 2D array of [2, 2] locations, where first 2 refers to 
        ;    left and right edges
        rec_xedge = [ [-4.25, -3.75], $
                      [ 3.75,  4.25] ]
        
        ;  Define Y edges of 2 rectangular apertures (in mm) 
        ;  - 2D array of [2, 2] locations, where first 2 refers to 
        ;    bottom and top edges
        rec_yedge = [ [ 2.10,  3.70], $
                      [-3.70, -2.10] ]
        
        ;  Check photon location against rectangular edges of the
        ;  large aperture areas
        for i=0, 1 do $
           rec_tran += ( ( rel_xpos gt rec_xedge[0, i] ) and $
                         ( rel_xpos lt rec_xedge[1, i] ) and $
                         ( rel_ypos gt rec_yedge[0, i] ) and $
                         ( rel_ypos lt rec_yedge[1, i] ) )
        
        ;  Combine circular and rectangular transmission tests 
        ;  (avoiding double counting in the semicircle areas that 
        ;  overlap the two ends of the rectangular apertures) to
        ;  set path length to 0 for photons falling on apertures
        path_len[ where(cir_tran or rec_tran) ] = 0.
        
     end
     ;  Photons fall within open rear grid area of coarse flare 
     ;  locator subcollimator
     strlowcase(subc.label) eq 'cfl' and rear : path_len[*] = 0.
     ;  Photons fall within a Fourier component front/rear grid area 
     ;  or coarse flare locator obscured front grid area
     else : begin
     
        ;  Initiate separate arrays for tracking grid/bridge 
        ;  transmission
        gri_tran = bytarr( n_pos )
        bri_tran = gri_tran
        
        ;  Determine photon location relative to centre of grid 
        rel_xpos = xpos - grid.x_cen 
        rel_ypos = ypos - grid.y_cen 
  
        ;  Determine if photons transmit through grid slit pattern
        ;clock = tic('periodic1')
        gri_tran = stx_sim_periodic_tran( rel_xpos, rel_ypos, grid.slit_wd, $
                                          grid.pitch, grid.angle, $
                                          cfl = strlowcase(subc.label) eq 'cfl' )
        
        
        ;  If a grid bridge does not exist then allow all photons
        if ( grid.b_width eq 0 ) then bri_tran[*] = 1 else $
           ;  Determine if photon is obscured by grid bridge pattern
           ;    N.B. this is also performed for the coarse flare 
           ;         locator subcollimator, as the front grid pattern 
           ;         horizontal slat is encoded as the grid bridge 
           ;         properties
           bri_tran = stx_sim_periodic_tran( rel_xpos, rel_ypos, (grid.b_pitch - grid.b_width), $
                                             grid.b_pitch, grid.b_angle )
        
        ;  Photons transmitted only when passing both the grid and
        ;  the bridge transmission tests
        ;path_len[ where(gri_tran and bri_tran) ] = 0.
        tran = gri_tran and bri_tran
        path_len = path_len * (1-tran)
        
     end
     
  endcase
  
  ;  Pass out photon material path length array
  return, path_len
  
end
