;+
; NAME:
;    stx_imaging_pipeline
;
; PURPOSE:
;    Read STIX L1 data and auxiliary data to construct a map using MEM_GE
;
; CALLING SEQUENCE:
;    result = stx_imaging_pipeline(stix_uid, time_range, energy_range, xy_flare [, imsize=imsize, pixel=pixel, x_ptg=x_ptg, y_ptg=y_ptg])
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
;   x_ptg, y_ptg : if provided, use these values instead of those found in the auxiliary file to correct for pointing
;
; OPTIONAL KEYWORDS:
;   force_sas    : if set, use SAS pointing solution even if very different from s/c pointing
;   no_sas       : if set, bypass SAS solution and use spacecraft pointing (corrected for systematics) instead
;   no_small     : if set, don't use small pixels data to generate the map
;
; OUTPUTS:
;   Returns a map object that can be displayed with plot_map
;
; EXAMPLES:
;   mem_ge_map = stx_imaging_pipeline('2109230031', ['23-Sep-2021 15:20:30', '23-Sep-2021 15:22:30'], [18,28], [650.,-650.])
;   map_1 = stx_imaging_pipeline('2110090002', ['2021-10-09T06:29:50','2021-10-09T06:32:30'], [18,28], [20., 420.])
;   map_2 = stx_imaging_pipeline('2110090002', ['2021-10-09T06:29:50','2021-10-09T06:32:30'], [4,8], [20., 420.])
;
; MODIFICATION HISTORY:
;    2022-05-19: F. Schuller (AIP, Germany): created
;    2022-08-30, FSc: use stx_estimate_location to find source position if not given
;    2022-09-09, FSc: added optional argument bkg_uid
;    2022-10-06, FSc: adapted to recent changes in other procedures
;    2023-02-24, FSc: added optional keyword no_small
;
;-
function stx_imaging_pipeline, stix_uid, time_range, energy_range, bkg_uid=bkg_uid, $
                               xy_flare=xy_flare, imsize=imsize, pixel=pixel, x_ptg=x_ptg, y_ptg=y_ptg, $
                               force_sas=force_sas, no_sas=no_sas, no_small=no_small
  if n_params() lt 3 then begin
    print, "STX_IMAGING_PIPELINE"
    print, "Syntax: result = stx_imaging_pipeline(stix_uid, time_range, energy_range [, xy_flare=xy_flare, imsize=imsize, pixel=pixel, x_ptg=x_ptg, y_ptg=y_ptg])"
    return, 0
  endif

  ; Input directories - TO BE ADAPTED depending on local installation - FIX ME!
  aux_data_folder = '/store/data/STIX/L2_FITS_AUX/'
;   l1a_data_folder = '/store/data/STIX/L1A_FITS/L1/'
  l1a_data_folder = '/store/data/STIX/L1_FITS_SCI/'

  default, imsize, [128, 128]
  default, pixel,  [2.,2.]

  ;;;;

  ; Extract pointing and other ancillary data from auxiliary file covering the input time_range.
  ; First, extract date from time_range[0]
  time_0 = anytim2utc(anytim(time_range[0], /tai), /ccsds)
  day_0 = strmid(str_replace(time_0,'-'),0,8)
  aux_fits_file = aux_data_folder + 'solo_L2_stix-aux-ephemeris_'+day_0+'_V01.fits'
  ; Extract data at requested time
  if ~file_test(aux_fits_file) then message,"Cannot find auxiliary data file "+aux_fits_file

  ; If an aspect solution is given as input, then use that one:
  if keyword_set(x_ptg) and keyword_set(y_ptg) then begin
    ; we still need to call stx_create_auxiliary_data to get RSUN, L0 and B0 ...
    aux_data = stx_create_auxiliary_data(aux_fits_file, time_range, /silent)
    ; ... but overwrite pointing terms with user input
    aux_data.stx_pointing[0] = x_ptg
    aux_data.stx_pointing[1] = y_ptg
  endif else aux_data = stx_create_auxiliary_data(aux_fits_file, time_range, force_sas=force_sas, no_sas=no_sas)
  
  
  ;;;;
  ; Read and process STIX L1A data
  l1a_file_list = file_search(l1a_data_folder + '*' + stix_uid + '*.fits')
  if l1a_file_list[0] eq '' then message,"Could not find any data for UID "+stix_uid $
     else path_sci_file = l1a_file_list[0]
  print, " INFO: Found L1(A) file "+path_sci_file

  if keyword_set(bkg_uid) then begin
    l1a_file_list = file_search(l1a_data_folder + '*' + bkg_uid + '*.fits')
    if l1a_file_list[0] eq '' then message,"Could not find any data for UID "+bkg_uid $
       else path_bkg_file = l1a_file_list[0]
  endif

  ; If not given, try to estimate the location of the source from the data
  !p.background=0
  if not keyword_set(xy_flare) then begin
    stx_estimate_flare_location, path_sci_file, time_range, aux_data, flare_loc=xy_flare, energy_range=energy_range
    print, xy_flare, format='(" *** INFO: Estimated flare location = (",F7.1,", ",F7.1,") arcsec")'
    print, xy_flare / aux_data.rsun, format='(" ... in units of solar radius = (",F6.3,", ",F6.3,")")'

  endif else mapcenter = xy_flare
  
  ; The coordinates given as input to the imaging pipeline have to be conceived in the STIX reference frame.
  ; Therefore, we perform a transformation from Helioprojective Cartesian to STIX reference frame with 'stx_hpc2stx_coord'
  mapcenter = stx_hpc2stx_coord(xy_flare, aux_data)
  flare_loc  = mapcenter

  ; Compute calibrated visibilities
  if keyword_set(no_small) then $
     vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter, $
                                               path_bkg_file=path_bkg_file, xy_flare=flare_loc, /no_small, sumcase='TOP+BOT') $
     else vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter, $
                                               path_bkg_file=path_bkg_file, xy_flare=flare_loc)

  ; Finally, generate the map using MEM_GE
  out_map = stx_mem_ge(vis,imsize,pixel,aux_data,total_flux=max(abs(vis.obsvis)), /silent)
  return, out_map
end
