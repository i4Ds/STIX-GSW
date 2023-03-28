;+
;
; NAME:
;
;   stx_calibrate_visibility
;
; PURPOSE:
;
;   Takes as input an uncalibrated 'stx_visibility' structure and returns as output the corresponding calibrated one.
;   The calibration process consists in the calibration of the visibility amplitudes and phases.
;
; CALLING SEQUENCE:
;
;   calibrated_vis = stx_calibrate_visibility(vis)
;
; INPUTS:
;
;   vis: uncalibrated visibility structure
;
; KEYWORDS:
; 
;   phase_calib_factors: 32-element array containing the phase calibration factors for each detectors (degrees).
;                        The default phase calibration factors consist of four terms:
;                         - a grid correction factor, which keeps into account the phase of the front and the rear grid;
;                         - a projection correction factor, if the 'xy_flare' estimate of the flare location is provided 
;                           in the visibility structure;
;                         - an "ad hoc" phase correction factor, which removes systematic residual errors. 
;                           The cause of these systematic errors is still under investigation;
;                         - a factor which is added so that the reconstructed image is centered in the 
;                           coordinates that are saved in the 'XYOFFSET' field of the input visibility structure
;   
;   amp_calib_factors: 32-element array containing amplitude calibration factors. The default values include just the
;                       modulation efficiency factor
;   
;   syserr_sigamp: float, percentage of systematic error to be added to the visibility amplitude errors. 
;                  Default, 5%
;   
;   f2r_sep: separation between the front and the rear grid (mm). Default, 550 mm. It is used for computing the default 
;            projection correction factors
;   
;   r2d_sep: separation between the rear grid and the detector (mm, used for the phase projection correction).
;            Default, 47 mm. It is used for computing the default 
;
; OUTPUTS:
;
;   Calibrated 'stx_visibility' structure.
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_calibrate_visibility, vis, phase_calib_factors=phase_calib_factors, amp_calib_factors=amp_calib_factors, $
                                        syserr_sigamp = syserr_sigamp, r2d_sep=r2d_sep, f2r_sep=f2r_sep

default, f2r_sep, 545.30
default, r2d_sep, 47.78

n_vis = n_elements(vis)

modulation_efficiency = !pi^3./(8.*sqrt(2.)) 

;; Grid phase correction
tmp = read_csv(loc_file( 'GridCorrection.csv', path = getenv('STX_VIS_PHASE') ), header=header, table_header=tableheader, n_table_header=2 )
grid_phase_corr = tmp.field2[vis.ISC - 1]; * (-vis.phase_sense)

;; Projection correction factor
xy_flare = vis[0].XY_FLARE
phase_proj_corr  = fltarr(n_vis)
if ~xy_flare[0].isnan() then begin
  proj_corr_factor = -xy_flare[0] * 360. * !pi / (180. * 3600. * 8.8) * (r2d_sep + f2r_sep/2.)
  phase_proj_corr = phase_proj_corr + proj_corr_factor
  ;phase_proj_corr  = phase_proj_corr * (-vis.phase_sense)
endif

;; "Ad hoc" phase correction (for removing residual errors)
tmp = read_csv(loc_file( 'PhaseCorrFactors.csv', path = getenv('STX_VIS_PHASE')), header=header, table_header=tableheader, n_table_header=3 )
ad_hoc_phase_corr = tmp.field2[vis.ISC - 1]; * (-vis.phase_sense)

;; Mapcenter correction
phase_mapcenter_corr = -2 * !pi * (vis.XYOFFSET[0] * vis.U + vis.XYOFFSET[1] * vis.V ) * !radeg

default, amp_calib_factors, fltarr(n_vis) + modulation_efficiency
default, phase_calib_factors, grid_phase_corr + ad_hoc_phase_corr + phase_proj_corr + phase_mapcenter_corr
default, syserr_sigamp, 0.05 ;; 5% systematic error in the visibility amplitudes; arbitrary choice

if vis[0].CALIBRATED eq 1 then message, "This visibility structure is already calibrated"

obsvis = vis.obsvis

vis_real = real_part(obsvis)
vis_imag = imaginary(obsvis)

vis_amp   = sqrt(vis_real^2 + vis_imag^2)
vis_phase = atan(vis_imag, vis_real) * !radeg

;; Calibrate amplitudes
calibrated_vis_amp   = vis_amp * amp_calib_factors
;; Calibrate phases
calibrated_vis_phase = vis_phase + phase_calib_factors
;; Calibrate sigamp
calibrated_sigamp = vis.sigamp * amp_calib_factors
calibrated_sigamp = sqrt(calibrated_sigamp^2 + syserr_sigamp^2 * calibrated_vis_amp^2.) ;; Add systematic error

calibrated_obsvis = complex(cos(calibrated_vis_phase * !dtor), sin(calibrated_vis_phase * !dtor)) * calibrated_vis_amp
 

;; Fill in calibrated visibility structure
calibrated_vis = vis

calibrated_vis.obsvis = calibrated_obsvis
calibrated_vis.sigamp = calibrated_sigamp
calibrated_vis.CALIBRATED = 1

return, calibrated_vis

end