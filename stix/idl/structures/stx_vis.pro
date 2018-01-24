;+
; :description:
;   This function creates 0 flux stix visibilities from the base subcollimator data structure
;   These are needed to build a visibility bag directly from a simulated map
;
; :categories:
;    visibility calculation
;
; :params:
;    subc_str : in, optional, type="stix sucollimator structure"
;               the stix subcollimator structure with all the grid and detector
;               configuration data
; :keywords:
;    f2r_sep   : in, type="double", default="550d"
;                the front to rear grid separation in mm
;    radius_au : distance from Solar Orbiter to the Sun in AU
;    _extra    : keyword inheritance allowed, not passed to anything internal (23-jul-2013)
;
; :returns:
;    an array of unique stx_visibility structures
;
; :examples:
;    subc_str = stx_construct_subcollimator( )
;    vis = stx_visgen(  [subc_str] )
;
; :restrictions:
;     At present, the pitch is only computed for a single spatial location relative to the Sun.  This
;     will change as Solar Orbiter changes its distance from the Sun
;
; :history:
;     18-apr-2013, Richard Schwartz, extracted from stx_visgen, added label tag
;                  and value for convenience. We need fields that reference the distance from
;                  the Sun and the subspace location of the sc/Sun line. Current reference
;                  system based on an Earth/Sun line orientation with fixed attitude to
;                  solar North. 
;     25-Oct-2013, Shaun Bloomfield (TCD), renamed subcollimator 
;                  reading routine stx_construct_subcollimator.pro
;     24-nov-2013, Richard Schwartz (gsfc), changed ltpair to live_time. This tag live_time refers
;                  to the ltpair assignment index for now. This needs to be made consistent.
;     27-nov-2014, Shaun Bloomfield (TCD), adapted to use subcollimator units of mm
;     30-Jun-2015, richard.schwartz@nasa.gov, rschwartz70@gmail.com 
;       changed to call stx_construct_visibility
;       AnnaMaria Massone correctly points out that the visibility angular measures do not change
;       with the distance to the Sun. This only matters when rendering a map on the Sun. For now this code
;       will the radius_au keyword will throw and error
             
;-
function stx_vis,  subc_str, f2r_sep=f2r_sep, radius_au=radius_au, $
    _extra = extra
  ; defaults
  return, stx_construct_visibility( subc_str, f2r_sep=f2r_sep, radius_au=radius_au, $
    _extra = extra )
  end
;  default, subc_str, stx_construct_subcollimator()
;  default, f2r_sep, 550.0
;  default, radius_au, 1.0 ;separation between Sun and Solar Orbiter in AU
;  
;  ; select indices of all subcollimators w/o background monitor and flare locator
;  subc_str_f_idx = where(subc_str.label ne 'cfl' and subc_str.label ne 'bkg')
;  
;  ; filter out background monitor and flare locator
;  subc_str_f = subc_str[subc_str_f_idx]
;  
;  ; take average of front and rear grid pitches (mm)
;  pitch = (subc_str_f.front.pitch + subc_str_f.rear.pitch) / 2.0
;  
;  ; take average of front and rear grid orientation
;  orientation = (subc_str_f.front.angle + subc_str_f.rear.angle) / 2.0
;  
;  ; convert pitch from mm to arcsec
;  pitch = pitch / f2r_sep * 3600.0 * !RADEG
;  
;  ; account for the distance from the Sun to Solar Orbiter
;  pitch = pitch * radius_au
;  
;  ; calculate number of frequency components
;  nfc = n_elements(subc_str_f)
;  
;  ; create a visibility bag for STIX
;  ; we use an anonymous structure for now until a single definition of {stx_visibility} is agreed upon
;  vis = replicate(stx_visibility(),  nfc)
;  
;      
;  ; assign detector numbers to visibility index of subcollimator (isc)
;  vis.isc = subc_str_f.det_n
;  
;  ; assign the stix sc label for convenience
;  vis.label = subc_str_f.label
;  
;  ; save phase orientation of the grids to the visibility
;  vis.phase_sense = subc_str_f.phase
;
;  
;  ; calculate u and v
;  uv = 1.0 / pitch
;  vis.u = uv * cos(orientation * !DTOR)
;  vis.v = uv * sin(orientation * !DTOR)
;  ;Add the livetime isc association. This gives the livetime pairings
;  ;This isn't the livetime, this is the livetime pair assignment index
;  ;This needs to be made consistent.  
;  vis.live_time = stx_ltpair_assignment( vis.isc )
;  return, vis
;end
