;+
; NAME:
;    stx_imaging_pipeline
;
; PURPOSE:
;    Read STIX L1 data and auxiliary data to construct a map using MEM_GE
;
; CALLING SEQUENCE:
;    result = stx_imaging_pipeline(stix_uid, time_range, energy_range, xy_flare [, imsize=imsize, pixel=pixel, y_srf=y_srf, z_srf=z_srf])
;    
; INPUTS:
;    stix_uid    : string giving the unique ID of the STIX L1 data
;    time_range  : start and end time to consider, in any format accepted by function anytim
;    energy_range: energy range to consider (in keV)
;    xy_flare    : position (quasi-heliocentric, in arcsec) of the flare, also used for map center
;
; OPTIONAL INPUTS:
;   imsize       : size (in pixels) of the image to be generated (default: [128, 128])
;   pixel        : size (in arcsec) of one pixel in the map (default: [2.,2.])
;   y_srf, z_srf : if provided, use these values instead of those found in the auxiliary file to correct for aspect solution
;
; OUTPUTS:
;   Returns a map object that can be displayed with plot_map
;
; EXAMPLES:
;   mem_ge_map = stx_imaging_pipeline('2109230031', ['23-Sep-2021 15:20:30', '23-Sep-2021 15:22:30'], [18,28], [650.,-650.])
;   mem_ge_map = stx_imaging_pipeline('2203026385', ['2022-03-02T17:31:30','2022-03-02T17:32:30'], [16,50], [-640.,580.], y_srf=-485., z_srf=-54.)
;   map_1 = stx_imaging_pipeline('2110090002', ['2021-10-09T06:29:50','2021-10-09T06:32:30'], [18,28], [20., 420.])
;   map_2 = stx_imaging_pipeline('2110090002', ['2021-10-09T06:29:50','2021-10-09T06:32:30'], [4,8], [20., 420.])
;
; MODIFICATION HISTORY:
;    2022-05-19: F. Schuller (AIP, Germany): created
;
;-
function stx_imaging_pipeline, stix_uid, time_range, energy_range, xy_flare, imsize=imsize, pixel=pixel, y_srf=y_srf, z_srf=z_srf
  if n_params() lt 4 then begin
    print, "STX_IMAGING_PIPELINE"
    print, "Syntax: result = stx_imaging_pipeline(stix_uid, time_range, energy_range, xy_flare [, imsize=imsize, pixel=pixel, y_srf=y_srf, z_srf=z_srf])"
    return, 0
  endif

  ; Input directories - TO BE ADAPTED depending on local installation - FIX ME!
  aux_data_folder = '/store/data/STIX/L2_FITS_AUX/'
  l1a_data_folder = '/store/data/STIX/L1A_FITS/L1/'

  default, imsize, [128, 128]
  default, pixel,  [2.,2.]

  ;;;;
  ; Read auxiliary file: first, extract date from time_range[0]
  time_0 = anytim2utc(anytim(time_range[0], /tai), /ccsds)
  day_0 = strmid(str_replace(time_0,'-'),0,8)
  aux_fits_file = aux_data_folder + 'solo_L2_stix-aux-auxiliary_'+day_0+'_V01.fits'
  ; Extract data at requested time
  if ~file_test(aux_fits_file) then message,"Cannot find auxiliary data file "+aux_fits_file
  aux_data = stx_create_auxiliary_data(aux_fits_file, time_range)
  ; If an aspect solution is given as input, use that one
  if keyword_set(y_srf) then aux_data.y_srf = y_srf
  if keyword_set(z_srf) then aux_data.z_srf = z_srf

  ;;;;
  ; Read and process STIX L1A data
  l1a_file_list = file_search(l1a_data_folder + '*' + stix_uid + '*.fits')
  if l1a_file_list[0] eq '' then message,"Could not find any data for UID "+stix_uid $
     else path_sci_file = l1a_file_list[0]
  mapcenter = xy_flare
  vis=stix2vis_sep2021(path_sci_file, time_range, energy_range, mapcenter, aux_data, path_bkg_file=path_bkg_file, xy_flare=xy_flare)
  out_map = stx_mem_ge(vis,imsize,pixel,aux_data,total_flux=max(abs(vis.obsvis)), /silent)
  return, out_map
end
