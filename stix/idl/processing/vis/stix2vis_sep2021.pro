;+
;
; NAME:
;   stix2vis_sep2021
;
; PURPOSE:
;   Function that returns a visbility structure from L1 data files
;
; CALLING SEQUENCE:
;   vis=stix2vis_sep2021(path_sci_file,path_bkg_file,time_range,energy_range)
;
; INPUTS:
;  path_sci_file: path of the science L1 fits file
;  path_bkg_file: path of the background L1 fits file
;  time_range: array containing the start and the end of the time interval to consider
;  energy_range: array containing lower and upper bound of the energy range to consider
;  mapcenter: coordinates of center of the map to reconstruct (heliocentric, north up).
;             Needed for adding the correct shift to the visibility phases.
;  aux_data: structure containing the SAS solution (if available for the considered time)
;
; OUTPUTS:
;   visibility structure corresponding to a given time range and a given energy range
;
; KEYWORDS:
;   xy_flare:   a priori estimate of the source location, needed for computing the transmission of the grids (heliocentric, north up)
;               and for the phase calibration
;   subc_index: index of the subcollimators to consider (default labels 10-3)
;   pixels:     for choosing the pixels to use ('TOP', 'BOT', 'TOP+BOT')
;   silent:     if set, plots are not displayed
;
; HISTORY: September 2021: wrapper around Paolo's first script
;          10-jan-2022, added keyword "shift_by_one"
;          26-jan-2022, xy_flare and mapcenter are cast as float array
;          01-may-2022, aux_data keyword added
;-

FUNCTION stix2vis_sep2021, path_sci_file, time_range, energy_range, mapcenter, aux_data, path_bkg_file=path_bkg_file, $
  xy_flare=xy_flare, subc_index=subc_index, pixels=pixels, silent=silent, shift_by_one=shift_by_one

  default, xy_flare, [0., 0.]
  default, subc_index, stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
                                       '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])
  default, pixels, 'TOP+BOT'

  mapcenter = float(mapcenter)
  xy_flare  = float(xy_flare)

  ;;;;;;;;;; make amplitudes and phases
  data = stix_compute_vis_amp_phase(path_sci_file,anytim(time_range),energy_range, xy_flare=xy_flare,bkg_file=path_bkg_file, $
    pixels=pixels, silent=silent, shift_by_one=shift_by_one, subc_index=subc_index)


  ;;;;;;;;;; CONSTRUCT VISIBILITY STRUCTURE
  ampobs = data.amp
  sigamp = data.sigamp
  phase = data.phase

  ; Phase projection correction
  L1 = 550.
  L2 = 47.
  phase -= xy_flare[1] * 360. * !pi / (180. * 3600. * 8.8) * (L2 + L1/2.)

  ; Construct visibility structure
  subc_str = stx_construct_subcollimator()
  vis = stx_construct_visibility(subc_str[subc_index])
  vis.u *= -vis.phase_sense
  vis.v *= -vis.phase_sense

  ; Compute real and imaginary part of the visibility
  vis.obsvis = ampobs[subc_index] * complex(cos(phase[subc_index] * !dtor), sin(phase[subc_index] * !dtor))

  ; Correct mapcenter:
  ; - if 'aux_data' contains the SAS solution, then we read it and we correct tha map center accordingly
  ; - if 'aux_data' does not contain the SAS solution, then we apply an average shift value to the map center
  mapcenter_corr_factors = read_csv(loc_file( 'Mapcenter_correction_factors.csv', path = getenv('STX_VIS_DEMO') ), $
                           header=header, table_header=tableheader, n_table_header=1 )
  if ~aux_data.Z_SRF.isnan() and ~aux_data.Y_SRF.isnan() then begin
    ; coor_mapcenter = SAS solution + discrepancy factor
    coor_mapcenter = [aux_data.Y_SRF, -aux_data.Z_SRF] + [mapcenter_corr_factors.FIELD3, mapcenter_corr_factors.FIELD4]
  endif else begin
    coor_mapcenter = [mapcenter_corr_factors.FIELD1,mapcenter_corr_factors.FIELD2]
  endelse
  ; Correct the mapcenter
  this_mapcenter = mapcenter - coor_mapcenter
  
  phase_mapcenter = -2 * !pi * (this_mapcenter[1] * vis.u - this_mapcenter[0] * vis.v )
  vis.obsvis *= complex(cos(phase_mapcenter), sin(phase_mapcenter))

  ; Set uncertainty on the visibility amplitudes
  vis.sigamp = sigamp[subc_index]

  vis.xyoffset = this_mapcenter

  ;sam: add time range
  time_l = stx_construct_time(time=time_range[0])
  time_r = stx_construct_time(time=time_range[1])

  vis.time_range=[time_l,time_r]
  vis.energy_range=energy_range

  return,vis

END

