; SAS_test.pro
; A short sample of commands to test that the SAS Pipeline procedures are running as expected.
; 
; F. Schuller (AIP Potsdam, Germany)
;    Created:     2021-08-06
;    Last modif.: 2022-01-31
; 

;;;;
; First, let's define paths to input directories and parameter files
;
data_dir = '/store/data/STIX/L1_FITS_HK/'
param_dir = '/home/fschuller/Documents/IDL/STIX-GSW/stix/idl/processing/aspect/SAS_param/'
calib_file = param_dir + 'SAS_calib_20211005.sav'
aperfile = param_dir + 'apcoord_FM_circ.sav'
simu_data_file = param_dir + 'SAS_simu.sav'   ; this can be a link to the actual file containing simulated data

;;;
; Read SPICE kernel: needed here to compute SPICE_DISC_SIZE
; NB: This won't be necessary once the data reading and formatting is done within STIXcore
spice_dir = getenv('SPICE_DIR')
spice_kernel = getenv('SPICE_KERNEL')
cspice_kclear
add_sunspice_mission, 'solo'
load_sunspice_solo
cspice_furnsh, spice_dir + spice_kernel

; Read data from L1 FITS file and store them in an array of stx_aspect_dto structures
; NB: This won't be necessary once the data reading and formatting is done within STIXcore
;
print,"Reading L1 data file..."
in_file = "solo_L1_stix-hk-maxi_20210401_V01.fits"
data = prepare_aspect_data(data_dir + in_file, quiet=0)
show_info, data

print,"Calibrating data..."
; First, substract dark currents and applies relative gains
stx_calib_sas_data, data, calib_file
; Now automatically compute global calibration correction factor and applies it
; Note: this takes a bit of time
stx_auto_scale_sas_data, data, simu_data_file, aperfile

print,"Plotting the signals..."
show_info, data
plot4sig, data

print,"Computing aspect solution..."
derive_aspect_solution, data, simu_data_file, interpol_r=1, interpol_xy=1
!p.multi = [0,1,2]
utplot, data.TIME, data.y_srf, /xs, /ynoz, ytit='!6Y!dSRF !n [arcsec]',chars=1.4
utplot, data.TIME, data.z_srf, /xs, /ynoz, ytit='!6Z!dSRF !n [arcsec]',chars=1.4
;;;;;;;;;;;;;;;;;


;;;;
; Alternatively, call "process_SAS_data" to do at once:
;  - calib_sas_data
;  - auto_scale_sas_data
;  - derive_aspect_solution
;
print,"End-to-end processing test..."
data_dir = '/store/data/STIX/L1_FITS_HK/'
in_file = "solo_L1_stix-hk-maxi_20210401_V01.fits"
data = prepare_aspect_data(data_dir + in_file, quiet=0)
cal_factor = 1.10   ; starting value, roughly OK for 2021 data [NB: this parameter is fully optional]
process_SAS_data, data, calib_file, simu_data_file, aperfile, cal_factor=cal_factor
; Now the results are stored in data.y_srf and data.z_srf
;
;;;;
