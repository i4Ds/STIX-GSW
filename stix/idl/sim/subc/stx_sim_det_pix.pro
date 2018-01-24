;+
; :description:
;    This function calculates pixel indices for an array of photon
;    locations in a given STIX subcollimator.
;
; :params:
;    pos:   in, required, type="float"
;           [n, 2]-element array containing the [n, [X, Y]] locations
;           for n photons in the STIX detector plane relative to the
;           STIX optical axis.
;
;    subc:  in, required, type="structure"
;           single-element subcollimator-specific geometry structure.
;
;    bkg:   in, required, type="long"
;           subcollimator-specific simulated background photon flux in
;           cm^-2. This is not the total number of background photons
;           simulated as being "recorded" in this detector, which is
;           instead 0.88 x 0.92 x bkg (i.e., detector has dimensions
;           of 8.8 mm by 9.2 mm).
;
; :keywords:
;
;
; :returns:
;    12-element vector containing the number of photon counts recorded
;    in each detector pixel.
;
; :errors:
;
;
; :history:
;    21-Aug-2012 - Shaun Bloomfield (TCD), created routine
;    30-Apr-2013 - Shaun Bloomfield (TCD), vectorized photon handling
;                  and added background flux
;    21-Aug-2013 - Shaun Bloomfield (TCD), fixed single photon bug
;    25-Oct-2013 - Shaun Bloomfield (TCD), incorporated modified
;                  subcollimator structure tagnames
;    05-Nov-2013 - Shaun Bloomfield (TCD), removed background photon
;                  generation (now in stx_sim_photon_path.pro)
;    13-Nov-2014 - Shaun Bloomfield (TCD), minor comment correction
;    11-Dec-2015 - Richard Schwartz, simplify internals by prereferencing subc structure
;                  and extracting left, right, bottom, top, Use xpos and ypos as separate vars for speed
;-
function stx_sim_det_pix, xpos, ypos, subc_det_pixel_edge ;pos, subc

  edge  = subc_det_pixel_edge
  bottom = edge.bottom
  top    = edge.top
  left   = edge.left
  right  = edge.right
  
  ;  Ensure that photon [X, Y] location array has coordinates in
  ;  the second dimension when only one photon being considered
  if ( n_elements(pos) eq 2 ) then pos = transpose(pos)
  ;clock = tic('zones')
  ;  a is true for lower half of detector (i.e., below the
  ;  bottom edge of the upper large pixels 0 to 3)
  a = ypos lt bottom[2]

  ;  b is true for right half of detector (i.e., to the 
  ;  right of the left edge of large pixels 2 and 6)
  b = xpos ge left[2]

  ;  c is true for the middle "half strip" of the detector
  ;  (i.e., to the right of the left edge of large pixels 1 
  ;  and 5, but also to the left of the left edge of large 
  ;  pixels 3 and 7)
  ;toc, clock
  ;clock = tic('zone cd')
  c = ( xpos ge left[1] ) and $
      ( xpos lt left[3] )
  
  ;  d is true for the vertical band encompassing the small
  ;  pixels (i.e., above the bottom edge of small pixels 8 
  ;  to 11, but also below the top edge of small pixels
  ;  8 to 11)
  d = ( ypos ge bottom[8] ) and $
      ( ypos lt top[8] )

  ;  e is true for the horizontal band encompassing the small
  ;  pixels. This is periodic when measured relative to the 
  ;  detector left edge, so take modulus on the scale of one 
  ;  large pixel width and test location (relative to detector 
  ;  left edge) for being less than one small pixel width
  ;toc, clock
  ;clock = tic( 'zone e')
  e = ( ( xpos - left[8] ) mod $
        ( left[9] - left[8] ) ) lt $
      ( right[8] - left[8] )

  ;  Create detector zone logic array for all incident photons
  ph_zones = [ [a], [b], [c], [d], [e] ]
  ;toc, clock
  ;  Initiate array for converting detector zone binary arrays
  ;  [a,b,c,d,e] into decimal values of 0 to 31
  bin2dec_fac = [16b, 8b, 4b, 2b, 1b]
  
  ;  Create array for 
  zone2pix_ind = bytarr(32)
  
  ;  Begin loop over all binary combinations of 5 photon zones 
  ;  (2^5 = 32 possibilities)
  ;clock = tic('dec2bin')
  for i=0b, 31 do begin
     ;  Convert decimal value into binary array
     dec2bin, i, bin_arr, /quiet
     ;  Trim out the 5 significant binary elements
     pix_map = bin_arr[3:*]
     ;  Apply logic circuit to map binary elements to their unique
     ;  pixel index in the range 0 to 11
;    bin2dec, [ (d AND e),  (NOT (d AND e) AND a),  b,  (b XOR c) ], p
     bin2dec, [ (pix_map[3] AND pix_map[4]),  (NOT (pix_map[3] AND pix_map[4]) AND pix_map[0]),  pix_map[1],  (pix_map[1] XOR pix_map[2]) ], pix_loc, /quiet
     ;  Fill decimal zone combination to pixel index mapping array
     zone2pix_ind[i] = pix_loc
  endfor
  ;toc, clock
  ;  Convert photon zone binary arrays into decimal values
  pix_dec = ph_zones # bin2dec_fac
  
  ;  Map photon zone decimal values into pixel indices
  pix_ind = zone2pix_ind[pix_dec]
  
  ;  Pass out n-element vector containing photon pixel indices
  return, pix_ind
  
end
