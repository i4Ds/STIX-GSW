;+
;
; NAME:
;
;   stx_pixel_data_summed2visibility
;
; PURPOSE:
;
;   Create an uncalibrated 'stx_visibility' structure from a 'stx_pixel_data_summed' structure
;
; CALLING SEQUENCE:
;
;   vis = stx_pixel_data_summed2visibility(pixel_data_summed)
;
; INPUTS:
;
;   pixel_data_summed: 'stx_pixel_data_summed' structure
;   
; KEYWORDS:
; 
;   subc_index: array containing the indexes of the subcollimators to be considered for computing the visibility
;               values
;               
;   mapcenter: two-element array containing the coordinates of the center of the map to reconstruct 
;              from the visibility values (STIX coordinate frame, arcsec)
;             
;   f2r_sep: distance between the front and the rear grid (mm, used for computing the values of the (u,v) frequencies)
;   
;
; OUTPUTS:
;
;   Uncalibrated 'stx_visibility' structure containing:
;   
;   - ISC: indices of the considered subcollimators
;   - LABEL: labels of the considered subcollimators
;   - LIVE_TIME: detector livetime 
;   - ENERGY_RANGE: two-element array containing the lower and upper edge of the considered energy interval
;   - TIME_RANGE: two-element 'stx_time' array containing the lower and upper edge of the considered time interval
;   - OBSVIS: complex array containing the visibility values
;   - TOT_COUNTS: total number of counts recorded by STIX during the flaring events
;   - TOT_COUNTS_BKG: estimate of the total number of background counts recorded during the flaring events
;   - TOTFLUX: estimate of the total flux recorded by each detector, i.e., A+B+C+D
;   - SIGAMP: estimate of the errors on the visibility amplitudes
;   - U: u coordinate of the frequencies sampled by the sub-collimators
;   - V: v coordinate of the frequencies sampled by the sub-collimators
;   - PHASE_SENSE: array containing the sense of the phase measured by the sub-collimator (-1 or 1 values)
;   - XYOFFSET: two-element array containing the coordinates of the center of the map to renconstruct from the
;                visibiity values (STIX coordinate frame, arcsec)
;   - XY_FLARE: two-element array containing the coordinates of the estimated flare location (STIX coordinate frame, arcsec). 
;               It is used for computing the grid transmission correction and the phase projection correction. 
;               If the 'xy_flare' field of the  input 'stx_pixel_data_summed' structure contains NaN values, no correction is applied 
;   - CALIBRATED: 0 if the values of the visibility amplitudes and phases are not calibrated, 1 otherwise   
;   
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_pixel_data_summed2visibility, pixel_data_summed, subc_index=subc_index, mapcenter=mapcenter, $
                                           f2r_sep=f2r_sep

default, mapcenter, [0.,0.]
default, f2r_sep, 545.30
default, subc_index, stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
                                    '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

;; Check: if one of the selected sub-collimators was not used, throw and error
detector_masks = pixel_data_summed.DETECTOR_MASKS[subc_index]
idx = where(detector_masks eq 0b, n_det)
if n_det gt 0 then message, "Subcollimators " + subc_label[idx] + " were not used during the flaring event. Do not select those subcollimators"

;;************** Construct subcollimator structure

subc_str = stx_construct_subcollimator()
subc_str = subc_str[subc_index]

;;************** Define (u,v) points

; take average of front and rear grid pitches (mm)
pitch = (subc_str.front.pitch + subc_str.rear.pitch) / 2.0d
; take average of front and rear grid orientation
orientation = (subc_str.front.angle + subc_str.rear.angle) / 2.0d
; convert pitch from mm to arcsec
pitch = pitch / f2r_sep * 3600.0d * !RADEG
; calculate u and v
uv = 1.0 / pitch
u = uv * cos(orientation * !DTOR) * (-subc_str.PHASE) ; TO BE REMOVED!
v = uv * sin(orientation * !DTOR) * (-subc_str.PHASE) ; TO BE REMOVED!

;;************** Define visibility values

count_rates     = pixel_data_summed.COUNT_RATES
count_rates     = count_rates[subc_index,*]
counts_rates_error = pixel_data_summed.COUNTS_RATES_ERROR
counts_rates_error = counts_rates_error[subc_index,*]

count_rates_bkg = pixel_data_summed.COUNT_RATES_BKG
count_rates_bkg = count_rates_bkg[subc_index,*]
count_rates_error_bkg = pixel_data_summed.COUNT_RATES_ERROR_BKG
count_rates_error_bkg = count_rates_error_bkg[subc_index,*]

;; Background subtraction
count_rates = count_rates - count_rates_bkg
counts_rates_error = sqrt(counts_rates_error^2 + count_rates_error_bkg^2)

;; A,B,C,D
A = count_rates[*,0]
B = count_rates[*,1]
C = count_rates[*,2]
D = count_rates[*,3]

totflux = A+B+C+D

dA = counts_rates_error[*,0]
dB = counts_rates_error[*,1]
dC = counts_rates_error[*,2]
dD = counts_rates_error[*,3]

;; Visibility amplitudes
vis_cmina = C-A
vis_dminb = D-B

dcmina = sqrt(dC^2 + dA^2)
ddminb = sqrt(dD^2 + dB^2)

vis_amp = sqrt(vis_cmina^2 + vis_dminb^2)
sigamp = sqrt( ((vis_cmina)/vis_amp*dcmina)^2+((vis_dminb)/vis_amp*ddminb)^2 )

;; Visibility phases
sumcase = pixel_data_summed.SUMCASE
case sumcase of

  'TOP':     begin
    phase_factor = 46.1
  end

  'BOT':     begin
    phase_factor = 46.1
  end

  'TOP+BOT': begin
    phase_factor = 46.1
  end

  'ALL': begin
    phase_factor = 45.0
  end

  'SMALL': begin
    phase_factor = 22.5
  end
end

vis_phase = atan(vis_dminb, vis_cmina) * !radeg + phase_factor
obsvis    = complex(cos(vis_phase * !dtor), sin(vis_phase * !dtor)) * vis_amp

;;************** Create and fill-in visibility structure

n_vis = n_elements(subc_index)
vis   = replicate(stx_visibility(),  n_vis)

vis.OBSVIS = obsvis
vis.SIGAMP = sigamp

vis.U = u
vis.V = v

vis.TOT_COUNTS   = pixel_data_summed.TOT_COUNTS
vis.TOT_COUNTS_BKG = pixel_data_summed.TOT_COUNTS_BKG
vis.TOTFLUX      = totflux
vis.ISC          = subc_str.DET_N
vis.LABEL        = subc_str.LABEL
vis.LIVE_TIME    = pixel_data_summed.LIVE_TIME[subc_index]
vis.ENERGY_RANGE = pixel_data_summed.ENERGY_RANGE
vis.TIME_RANGE   = pixel_data_summed.TIME_RANGE
vis.PHASE_SENSE  = subc_str.PHASE
vis.XYOFFSET     = mapcenter
vis.XY_FLARE     = pixel_data_summed.XY_FLARE

return, vis

end
