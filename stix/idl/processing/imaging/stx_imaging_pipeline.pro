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
;   force_sas    : if set, uses SAS solution even if it's far off SolO's pointing
;   no_sas       : if set, don't use SAS solution but rely on SolO's pointing
;   subc_labels  : list of sub-collimators to be used in imaging algorithm
;
; OPTIONAL KEYWORDS:
;   force_sas    : if set, use SAS pointing solution even if very different from s/c pointing
;   no_sas       : if set, bypass SAS solution and use spacecraft pointing (corrected for systematics) instead
;   no_small     : if set, don't use small pixels data to generate the map
;   method       : select imaging algorithm; should be one of: "MEM" [default], "EM", or "clean"
;   w_clean      : for clean method, choose between uniform weighting (w_clean=1, default) and natural weighting (w_clean=0)
;   clean_beam_width : for clean method, size of the beam to convolve the clean components with
;   set_clean_boxes  : should the user define the clean boxes interactively? (default: NO)
;   
; OUTPUTS:
;   Returns a map object that can be displayed with plot_map
;   
; OPTIONAL OUTPUT:
;   path_sci_file : contains the full path to the L1 SCI data file used as input
;
; EXAMPLES:
;   mem_ge_map = stx_imaging_pipeline('2109230031', ['23-Sep-2021 15:20:30', '23-Sep-2021 15:22:30'], [18,28])
;   map_1 = stx_imaging_pipeline('2110090002', ['2021-10-09T06:29:50','2021-10-09T06:32:30'], [18,28])
;   map_2 = stx_imaging_pipeline('2110090002', ['2021-10-09T06:29:50','2021-10-09T06:32:30'], [4,8])
;; Example with user-provided pointing correction:
;   map1 = stx_imaging_pipeline('2204020888', ['2022-04-02T13:18:10','2022-04-02T13:20:40'], [25,50], $
;                               x_ptg=-1901.0, y_ptg=871.3)
;; User-defined map center and dimensions:
;   map2 = stx_imaging_pipeline('2204020888', ['2022-04-02T13:22:30','2022-04-02T13:26:50'], [25,50], $
;                               x_ptg=-1900.0, y_ptg=871.2, xy_flare=[-1900.,550.], imsize=[261,221], pixel=[2.5,2.5])
;; Using only a sub-set of collimators:
;   low_res = ['10a','10b','10c','9a','9b','9c','8a','8b','8c','7b','7c','6c']
;   map_th = stx_imaging_pipeline('2204020888', ['2022-04-02T13:37','2022-04-02T13:44'], [4,8], $
;                                 x_ptg=-1897., y_ptg=870.3, xy_flare=[-2000.,600.], imsize=[201,201], pixel=[3.,3.], subc_labels = low_res)
;
; MODIFICATION HISTORY:
;    2022-05-19: F. Schuller (AIP, Germany): created
;    2022-08-30, FSc: use stx_estimate_location to find source position if not given
;    2022-09-09, FSc: added optional argument bkg_uid
;    2022-10-06, FSc: adapted to recent changes in other procedures
;    2022-11-16, FSc: added optional argument subc_labels
;    2023-02-24, FSc: added optional keyword no_small
;    2023-09-06, FSc: added optional keyword method
;    2023-10-04, FSc: use highest version number of AUX file if several available
;    2023-10-16, FSc: added optional keywords clean_beam_width and set_clean_boxes
;
;-
function stx_imaging_pipeline, stix_uid, time_range, energy_range, bkg_uid=bkg_uid, xy_flare=xy_flare, $
                               imsize=imsize, pixel=pixel, x_ptg=x_ptg, y_ptg=y_ptg, force_sas=force_sas, no_sas=no_sas, $
                               subc_labels=subc_labels, no_small=no_small, method=method, $
                               w_clean=w_clean, clean_beam_width=clean_beam_width, set_clean_boxes=set_clean_boxes, $
                               path_sci_file=path_sci_file

  if n_params() lt 3 then begin
    print, "STX_IMAGING_PIPELINE"
    print, "Syntax: result = stx_imaging_pipeline(stix_uid, time_range, energy_range [, bkg_uid=bkg_uid, xy_flare=xy_flare, $"
    print, "                 imsize=imsize, pixel=pixel, x_ptg=x_ptg, y_ptg=y_ptg, force_sas=force_sas, no_sas=no_sas, $"
    print, "                 subc_labels=subc_labels, no_small=no_small, method=method, w_clean=w_clean, $
    print, "                 clean_beam_width=clean_beam_width, set_clean_boxes=set_clean_boxes, path_sci_file=path_sci_file])"
    return, 0
  endif

  ; Input directories - TO BE ADAPTED depending on local installation - FIX ME!
  aux_data_folder = '/net/galilei/store/data/STIX/L2_FITS_AUX/'
  l1a_data_folder = '/net/galilei/store/data/STIX/L1_FITS_SCI/'

  
  ; sub-collimator labels
  default, subc_labels, ['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c','6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c']
  subc_index = stx_label2ind(subc_labels)

  default, imsize, [128, 128]
  default, pixel,  [2.,2.]
  
  ; Imaging algorithm to be used: make sure that the method is implemented
  default, method, "MEM"
  method = strupcase(method)
  known_methods = ["MEM", "EM", "CLEAN"]
  tst = where(known_methods eq method, i_tst)
  if ~i_tst then begin
    print, method, format='("Method ",A," not known. Please use one of the following:")'
    print, known_methods
    return, 0
  endif

  ;;;;

  ; Extract pointing and other ancillary data from auxiliary file covering the input time_range.
  ; First, find out the starting date from time_range[0]:
  time_0 = anytim2utc(anytim(time_range[0], /tai), /ccsds)
  day_0 = strmid(str_replace(time_0,'-'),0,8)
  
  aux_fits_file = aux_data_folder + 'solo_L2_stix-aux-ephemeris_'+day_0+'*.fits'
  aux_file_list = file_search(aux_fits_file, count=nb_aux)
  if nb_aux gt 0 then begin
    aux_fits_file = aux_file_list[-1]  ; this should be the highest version, since FILE_SEARCH sorts the list of files returned
    print, " STX_IMAGING_PIPELINE - INFO: Found AUX file " + aux_fits_file
  endif else message,"Cannot find auxiliary data file " + aux_fits_file
  
  ; Check if the time range runs over two consecutive days (fixes issue #162)
  time_end = anytim2utc(anytim(time_range[1], /tai), /ccsds)
  day_end = strmid(str_replace(time_end,'-'),0,8)
  if day_end ne day_0 then begin
    aux_fits_file_1 = aux_fits_file
    aux_fits_file_2 = aux_data_folder + 'solo_L2_stix-aux-ephemeris_'+day_end+'*.fits'
    aux_file_list_2 = file_search(aux_fits_file_2, count=nb_aux)
    if nb_aux gt 0 then begin
      aux_fits_file_2 = aux_file_list_2[-1]
      print, " STX_IMAGING_PIPELINE - INFO: Found AUX file " + aux_fits_file_2
    endif else message,"Cannot find auxiliary data file " + aux_fits_file_2
    aux_fits_file = [aux_fits_file_1, aux_fits_file_2]
  endif

  ; Extract data at requested time
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
  print, " STX_IMAGING_PIPELINE - INFO: Found L1(A) file "+path_sci_file

  if keyword_set(bkg_uid) then begin
    l1a_file_list = file_search(l1a_data_folder + '*' + bkg_uid + '*.fits')
    if l1a_file_list[0] eq '' then message,"Could not find any data for UID "+bkg_uid $
       else path_bkg_file = l1a_file_list[0]
  endif

  ; If not given, try to estimate the location of the source from the data
  !p.background=0
  if not keyword_set(xy_flare) then begin
    stx_estimate_flare_location, path_sci_file, time_range, aux_data, $
                                 flare_loc=xy_flare, energy_range=energy_range, subc_index=subc_index
    print, xy_flare, format='(" *** INFO: Estimated flare location = (",F7.1,", ",F7.1,") arcsec")'
    print, xy_flare / aux_data.rsun, format='(" ... in units of solar radius = (",F6.3,", ",F6.3,")")'

  endif else mapcenter = xy_flare
  
  ; The coordinates given as input to the imaging pipeline have to be conceived in the STIX reference frame.
  ; Therefore, we perform a transformation from Helioprojective Cartesian to STIX reference frame with 'stx_hpc2stx_coord'
  mapcenter = stx_hpc2stx_coord(xy_flare, aux_data)
  flare_loc  = mapcenter

  ; Next, we call the functions that take the data as input and generate the emission map. The functions
  ; to be called depend on the imaging algorithm.
  
  if method eq "EM" then begin
    pixel_data_summed = stx_construct_pixel_data_summed(path_sci_file, time_range, energy_range, $
                                                        path_bkg_file=path_bkg_file, xy_flare=xy_flare)

    out_map = stx_em(pixel_data_summed, aux_data, imsize=imsize, pixel=pixel,mapcenter=mapcenter)

  endif else begin
    ; Compute calibrated visibilities
    if keyword_set(no_small) then $
      vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter, subc_index=subc_index, $
      path_bkg_file=path_bkg_file, xy_flare=flare_loc, /no_small, sumcase='TOP+BOT') $
    else vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range, mapcenter, subc_index=subc_index, $
      path_bkg_file=path_bkg_file, xy_flare=flare_loc)

    case method of
      "MEM": out_map = stx_mem_ge(vis,imsize,pixel,aux_data,total_flux=max(abs(vis.obsvis)), /silent)
      "CLEAN": begin
        default, w_clean, 1  ; 1 = uniform weighting, 0 = natural weighting
        niter  = 100   ; Number of iterations
        gain   = 0.1   ; Gain used in each clean iteration
        nmap   = 10    ; Plot clean components and cleaned map every 10 iterations
        if not keyword_set(clean_beam_width) then clean_beam_width = 14. ; clean components are convolved with this beam
        if not keyword_set(set_clean_boxes) then set_clean_boxes = 0
        clean_map=stx_vis_clean(vis, aux_data, niter=niter, image_dim=imsize[0], PIXEL=pixel[0], $
                                uniform_weighting = w_clean, gain=gain, nmap=nmap, $
                                /plot, set_clean_boxes = set_clean_boxes, beam_width=clean_beam_width)

        out_map = clean_map[0]   ; contains the CLEAN map
      end
    endcase
  endelse

  return, out_map
end
