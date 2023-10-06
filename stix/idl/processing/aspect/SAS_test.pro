; SAS_test.pro
; A short sample of commands to test that the SAS Pipeline procedures are running as expected.
; 
; F. Schuller (AIP Potsdam, Germany)
;    Created:     2021-08-06
;    Last modif.: 2023-09-19
; 

;;;;
; First, let's define paths to input directories and parameter files
;
data_dir = '/store/data/STIX/L1_FITS_HK/'
param_dir = getenv('SAS_PARAM_DIR')
def_calibfile = getenv('SAS_CALIBFILE')
calib_file = param_dir +def_calibfile
aperfile = param_dir + 'apcoord_FM_circ.sav'
; simu_data_file = param_dir + 'SAS_simu.sav'   ; this can be a link to the actual file containing simulated data
simu_data_file = param_dir + getenv('SAS_DATA_SIMU')

; Read data from L1 FITS file and store them in an array of stx_aspect_dto structures
; NB: This won't be necessary once the data reading and formatting is done within STIXcore
;
print,"Reading L1 data file..."

one_day = '20230330'    ; case where the HK file contains too many rows (duplicate entries, many with duration close to 0)
; one_day = '20220509'    ; solar distance gets beyond 0.75 AU at the end of that day
; one_day = '20230321'    ; pointing mostly at Sun centre, with a flat-field calib. from 19:00 to 20:00
; one_day = '20230329'    ; includes pointing at pole, and other off-centre pointings

in_file = "solo_L1_stix-hk-maxi_"+one_day+"_V01.fits"
data = prepare_aspect_data(data_dir + in_file, quiet=0)
show_info, data

print,"Calibrating data..."
; First, substract dark currents and applies relative gains
stx_calib_sas_data, data, calib_file
; copy result in a new object
data_calib = data
; Added 2023-09-18: remove data points with some error detected during calibration
stx_remove_bad_sas_data, data_calib

; Now automatically compute global calibration correction factor and applies it
; Note: this takes a bit of time
stx_auto_scale_sas_data, data_calib, simu_data_file, aperfile

print,"Plotting the signals..."
show_info, data_calib
plot4sig, data_calib

; apply same calibration correction factor to all data (including data points that were removed due to errors)
cal_corr_factor = data_calib[0].calib
data.CHA_DIODE0 *= cal_corr_factor
data.CHA_DIODE1 *= cal_corr_factor
data.CHB_DIODE0 *= cal_corr_factor
data.CHB_DIODE1 *= cal_corr_factor

print,"Computing aspect solution..."
stx_derive_aspect_solution, data, simu_data_file, interpol_r=1, interpol_xy=1
!p.multi = [0,1,2]
; Only plot solution with no error message
good = where(data.ERROR eq '')
utplot, data[good].TIME, data[good].y_srf, /xs, /ynoz, ytit='!6Y!dSRF !n [arcsec]',chars=1.4,/psym
utplot, data[good].TIME, data[good].z_srf, /xs, /ynoz, ytit='!6Z!dSRF !n [arcsec]',chars=1.4,/psym
;;;;;;;;;;;;;;;;

end
