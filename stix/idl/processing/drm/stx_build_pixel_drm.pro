;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_build_pixel_drm
;
; :purpose:
;    Calculates the STIX detector response matrix with respect to the input energy bins
;    taking account of the fact pixels of differing sizes are present in the STIX detectors
;
;
; :category:
;       helper methods
;
; :description:
;    A wrapper for stx_build_pixel_drm. Computes the energy loss matrix, pulse height matrix
;    the detector response matrix for a given energy binning scaled by the area of pixels supplied by the pixel mask
;    returned matrices are (n_ebins, n_ebins) arrays
;
; :params:
;   ct_energy_edges - 1dim floating point array of energy edges of e-bins (for STIX 33 elements array from 4 to 150 keV)
;   pixel_mask - 12 x 32 element pixel mask of 1s and 0s repenting the pixels from each detector to be used
;
; :keywords:
;  ph_energy_edges
;  attenuator = 0 - no attenuator, 1 - include the attenuator
;  d_al - thickness of Al attenuator, default, 600 microns
;  d_be - effective thickness of Be window, default, 3.5 mm
;
;  func_par - parameters used with fwhm function, experts only
;  func - function for resolution broadening default is stx_fwhm
;  efficiency - photopeak efficiency, multiply by area to get counts and not counts/cm2
;  verbose
;
; :returns:
;    Returns the structure stx_drm containing the detector response matrix, pulse height matrix, energy loss matrix,
;    all scaled by the total area of pixels supplied by the pixel mask
;    STIX energy edges, STIX mean energies of bins, energy bin widths and input parameters
;
;
; :calling sequence:
;    IDL> stx_pxl_drm = stx_build_pixel_drm(ct_edges1,pixel_mask)
;
;
; :history:
;       23-Sep-2014 – ECMD (Graz)
;       26-Nov-2014 - Shaun Bloomfield (TCD), fixed bug from earlier
;                     conversion of stx_construct_subcollimator() to
;                     output areas in cm^2
;       03-Dec-2018 – ECMD (Graz), rcr area change
;                                  grids default is nominal 25%
;                                  presence of attenuator
;
;
;-
function stx_build_pixel_drm, ct_energy_edges, pixel_mask, ph_energy_edges = ph_energy_edges,rcr = rcr, grid_factor= grid_factor,dist_factor= dist_factor, _extra = _extra

  default, pixel_mask , intarr(12,32) + 1  ; default pixel mask is all pixels from all detectors
  default, grid_factor, 1./4.
  default, dist_factor, 1.

  default, ph_energy_edges, findgen(1471)*.1+3
  rcr_area  = stx_rcr_area(rcr)
  attenuator = rcr < 1
  pixel_mask = pixel_mask <1
  ;the input pixel mask must be a 12 x 32 element of 1s and 0s repenting the pixels from each detector to be used
  if (((size(pixel_mask))[1] ne 12) and ((size(pixel_mask))[2] ne 32) ) then begin
    print, 'Pixel mask must be an array of dimensions 12 (pixels) x 32 (detectors) using
    print, 'default of all pixels all detectors'
    pixel_mask = intarr(12,32) + 1
  endif

  ;get array of areas (in cm^2) of each pixel in each detector
  subc_str = stx_construct_subcollimator()
  pixel_areas = subc_str.det.pixel.area

  rcr_factor =  rcr_area/(subc_str.det.area)[0]

  ph_energy_edges =  get_uniq( [ph_energy_edges,ct_energy_edges],epsilon=0.0001)

  ; calculate the drm over the given count energy edges along with any other relevant keywords supplied
  ; using the standard build drm  routine
  drm = stx_build_drm( ph_energy_edges, d_be = 0, d_al = 0, _extra=_extra )

  ;calculate the total area of pixels to be included (multiply the elements in the mask by the elements in ther area array)
  total_area = total( pixel_areas*pixel_mask )


  ;the scale factor is calculated form the ratio of the area of pixels used to the area used to calculate the drm (currently 1 cm^2)
  scale_factor  = total_area/drm.area

  ;scale the relevant parameters
  drm.area *= scale_factor*grid_factor*rcr_factor*dist_factor

  det_mask = total(pixel_mask,1) <1
  smatrix = drm.smatrix
  transmission = stx_transmission(drm.emean, det_mask, attenuator = attenuator)
  dim_drm = size(/dim, smatrix) > 1

  smatrix = smatrix * rebin( transpose(transmission), dim_drm)

  data_grouper_edg, smatrix, drm.edges_out, ct_energy_edges, /perwidth, epsilon =0.0001, error=error, emsg=emsg
  drm = rep_tag_value(drm, ct_energy_edges, 'edges_out')
  drm = rep_tag_value(drm, smatrix, 'smatrix')


  return, drm
end
