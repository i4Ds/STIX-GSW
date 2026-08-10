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
;   mapcenter: two-element array containing the coordinates of the center of the map to reconstruct
;              from the visibility values (STIX coordinate frame, arcsec). It is used during the visibility phase calibration
;              process. A phase factor is added to the visibilities so that coordinates saved in 'mapcenter' become the
;              center of the reconstructed map.
; 
;   xy_flare: two-element array containing the coordinates of the estimated flare location (STIX coordinate frame, arcsec).
;             It is used for computing the grid transmission correction within the visibility amplitude calibration. Default, (0,0)
; 
;   phase_calib_factors: 32-element array containing the phase calibration factors for each detector (degrees).
;                        The default phase calibration factors consist of four terms:
;                         - a grid correction factor, which keeps into account the phase of the front and the rear grid;
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
; OUTPUTS:
;
;   Calibrated 'stx_visibility' structure.
;
; HISTORY: August 2022, Massa P., created
;          July 2023, Massa P., removed visibility phase 'projection correction' since the new definition of 
;          (u,v)-points is adopted (see stx_uv_points).
;          February 2026, Massa P., new visibility amplitude calibration is implemented
;          March 2026, Massa P., 'mapcenter' keyword is added here. Also 'f2r_sep' and 'r2d_sep' keyword are removed as not needed
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_calibrate_visibility, vis, mapcenter=mapcenter, xy_flare=xy_flare, phase_calib_factors=phase_calib_factors, amp_calib_factors=amp_calib_factors, $
                                   syserr_sigamp = syserr_sigamp

default, mapcenter, [0.,0.]
default, xy_flare, [0.,0.]

n_vis = n_elements(vis)

;; Compute subcollimator transmission to perform amplitude modulation
subc_transm = stx_subc_transmission(xy_flare, /simple_transm)

subc_transm = subc_transm[vis.ISC - 1]
slit2pitch = sqrt(subc_transm)

modulation_efficiency = !pi^3./(8.*sqrt(2.)) / sin(!pi * slit2pitch)^2


;; Grid phase correction
tmp = read_csv(loc_file( 'GridCorrection.csv', path = getenv('STX_VIS_PHASE') ), header=header, table_header=tableheader, n_table_header=2 )
grid_phase_corr = tmp.field2[vis.ISC - 1]

;; "Ad hoc" phase correction (for removing residual errors)
tmp = read_csv(loc_file( 'PhaseCorrFactors.csv', path = getenv('STX_VIS_PHASE')), header=header, table_header=tableheader, n_table_header=3 )
ad_hoc_phase_corr = tmp.field2[vis.ISC - 1]

;; Mapcenter correction
phase_mapcenter_corr = -2 * !pi * (mapcenter[0] * vis.U + mapcenter[1] * vis.V ) * !radeg

default, amp_calib_factors, fltarr(n_vis) + modulation_efficiency
default, phase_calib_factors, grid_phase_corr + ad_hoc_phase_corr + phase_mapcenter_corr
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

calibrated_vis.XY_FLARE = xy_flare
calibrated_vis.XYOFFSET = mapcenter

return, calibrated_vis

end