;+
; :description:
;     This function defines the stx_subc_edge structure.
; 
;     Structure contains the edge locations of the active area
;     extremities for one STIX subcollimator element (i.e., grid,
;     detector, pixel).
;       X locations are defined wrt the STIX optical axis, with the
;     positive direction measured to the right when viewed from Sun.
;       Y locations are defined wrt the STIX optical axis, with the
;     positive direction measured upwards when viewed from Sun.
; 
; :modification history:
;     24-Oct-2013 - Shaun Bloomfield (TCD), initial release
;     01-Nov-2013 - Shaun Bloomfield (TCD), made anonymous
;     28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;-
function stx_edge_structure
  
  str = {                  $ ; anonymous structure
          type:'stx_edge', $ ; structure name
          left:0.,         $ ; Left edge location [mm]
          right:0.,        $ ; Right edge location [mm]
          bottom:0.,       $ ; Bottom edge location [mm]
          top:0.           $ ; Top edge location [mm]
        }
  
  return, str
  
end

;+
; :description:
;     This function defines the stx_pixel structure.
; 
;     Structure contains the basic location and geometry information
;     for one STIX pixel.
;       X locations are defined wrt the STIX optical axis, with the
;     positive direction measured to the right when viewed from Sun.
;       Y locations are defined wrt the STIX optical axis, with the
;     positive direction measured upwards when viewed from Sun.
;       For large pixels, stx_pixel.area will not be the same as
;     ( stx_pixel.xsize * stx_pixel.ysize ) as small pixels remove
;     part of the active area in the lower- or upper- left corners.
; 
; :modification history:
;     24-Oct-2013 - Shaun Bloomfield (TCD), initial release
;     01-Nov-2013 - Shaun Bloomfield (TCD), made anonymous
;     28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;                   and areas to cm^2
;-
function stx_pixel_structure
  
  str = {                           $ ; anonymous structure
          type:'stx_pixel',         $ ; structure name
          x_cen:0.,                 $ ; Pixel centroid in X [mm]
          y_cen:0.,                 $ ; Pixel centroid in Y [mm]
          xsize:0.,                 $ ; Pixel width in X [mm]
          ysize:0.,                 $ ; Pixel height in Y [mm]
          area:0.,                  $ ; Pixel active area [cm^2]
          edge:stx_edge_structure() $ ; Pixel edge substructure
        }
  
  return, str
  
end

;+
; :description:
;     This function defines the stx_detector structure.
; 
;     Structure contains the basic location and geometry information
;     for one STIX detector.
;       X locations are defined wrt the STIX optical axis, with the
;     positive direction measured to the right when viewed from Sun.
;       Y locations are defined wrt the STIX optical axis, with the
;     positive direction measured upwards when viewed from Sun.
; 
; :modification history:
;     24-Oct-2013 - Shaun Bloomfield (TCD), initial release
;     01-Nov-2013 - Shaun Bloomfield (TCD), made anonymous
;     28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;                   and areas to cm^2
;-
function stx_detector_structure
  
  str = {                            $ ; anonymous structure
          type:'stx_detector',       $ ; structure name
          x_cen:0.,                  $ ; Detector centroid in X [mm]
          y_cen:0.,                  $ ; Detector centroid in Y [mm]
          xsize:0.,                  $ ; Detector width in X [mm]
          ysize:0.,                  $ ; Detector height in Y [mm]
          area:0.,                   $ ; Detector active area [cm^2]
          edge:stx_edge_structure(), $ ; Detector edge substructure
          pixel:replicate( stx_pixel_structure(), 12 ) $ ; 12 pixel 
                                                         ; substructures
        }
  
  return, str
  
end

;+
; :description:
;     This function defines the stx_grid structure.
; 
;     Structure contains the basic location and geometry information
;     for one STIX grid.
;       X locations are defined wrt the STIX optical axis, with the
;     positive direction measured to the right when viewed from Sun.
;       Y locations are defined wrt the STIX optical axis, with the
;     positive direction measured upwards when viewed from Sun.
;       Angles are measured CCW from the STIX positive Y axis when 
;     viewed from the Sun.
; 
; :modification history:
;     24-Oct-2013 - Shaun Bloomfield (TCD), initial release
;     01-Nov-2013 - Shaun Bloomfield (TCD), made anonymous
;-
function stx_grid_structure
  
  str = {                            $ ; anonymous structure
          type:'stx_grid',           $ ; structure name
          x_cen:0.,                  $ ; Grid centroid in X [mm]
          y_cen:0.,                  $ ; Grid centroid in Y [mm]
          xsize:0.,                  $ ; Grid width in X [mm]
          ysize:0.,                  $ ; Grid height in Y [mm]
          area:0.,                   $ ; Grid active area [cm^2]
          edge:stx_edge_structure(), $ ; Grid edge substructure
          slit_wd:0.,                $ ; Grid slit width [mm]
          pitch:0.,                  $ ; Grid pitch [mm]
          angle:0.,                  $ ; Grid slit orientation [degrees]
          b_width:0.,                $ ; Grid bridge slat width [mm]
          b_pitch:0.,                $ ; Grid bridge pitch [mm]
          b_angle:0.                 $ ; Grid bridge slat orientation [degrees]
        }
  
  return, str
  
end

;+
; :description:
;     This function defines the stx_subcollimator structure.
; 
;     Structure contains the basic location and geometry information
;     for one STIX subcollimator. Structure contains one front grid,
;     one rear grid and one detector (with 12 pixels).
;       X locations are defined wrt the STIX optical axis, with the
;     positive direction measured to the right when viewed from Sun.
;       Y locations are defined wrt the STIX optical axis, with the
;     positive direction measured upwards when viewed from Sun.
;       Angles are measured CCW from the STIX positive Y axis when 
;     viewed from the Sun.
;       For large pixels, stx_subcollimator.det.pixel.area will not
;     be the same as ( stx_subcollimator.det.pixel.xsize * 
;     stx_subcollimator.det.pixel.ysize ) as small pixels remove part
;     of the active area in the lower- or upper- left corners.
; 
; :modification history:
;     24-Oct-2013 - Shaun Bloomfield (TCD), initial release
;     01-Nov-2013 - Shaun Bloomfield (TCD), made anonymous
;-
function stx_subcollimator_structure
  
  str = {                              $ ; anonymous structure
          type:'stx_subcollimator',    $ ; structure name
          det_n:0b,                    $ ; STIX detector number [1-32]
          label:'',                    $ ; STIX resolution/orientation label ['1-10'+'a-c']
          phase:0,                     $ ; STIX front/rear grid phase [-1 or 1]
          front:stx_grid_structure(),  $ ; Grid substructure
          rear:stx_grid_structure(),   $ ; Grid substructure
          det:stx_detector_structure() $ ; Detector substructure
        }
  
  return, str
  
end
