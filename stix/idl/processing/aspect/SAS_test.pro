; SAS_test.pro
; A short sample of commands to test that the SAS Pipeline procedures are running as expected.
; 
; F. Schuller (AIP Potsdam, Germany) -  2021-08-06
; 
;; @configure    ; this defines the I/O directories and loads the relevant SPICE kernels
@configure    ; changed 2021-11-15: this only loads the SPICE kernels; no common block used anymore.
              ; All the I/O directories and parameters are defined in this script.

print,"Reading L1 data file..."
in_file = "solo_L1_stix-hk-maxi_20210401_V01.fits"
; data_dir = getenv('SAS_DATA_DIR')
data_dir = '/store/data/STIX/L1_FITS_HK/'
data = read_hk_data(data_dir + in_file, quiet=0)
show_info, data

print,"Calibrating data..."
; param_dir = getenv('SAS_PARAM_DIR')
; def_calibfile = getenv('SAS_CALIBFILE')
param_dir = '/home/fschuller/Documents/IDL/STIX-GSW/stix/idl/processing/aspect/SAS_param/'
calib_file = param_dir + 'SAS_calib_20211005.sav'
aperfile = param_dir + 'apcoord_FM_circ.sav'

calib_sas_data, data, calib_file
simu_data_file = param_dir + 'SAS_simu.sav'
auto_scale_sas_data, data, simu_data_file, aperfile

print,"Plotting the signals..."
show_info, data
plot4sig, data

print,"Computing aspect solution..."
derive_aspect_solution, data, simu_data_file, interpol_r=1, interpol_xy=1
!p.multi = [0,1,2]
utplot, data.utc, data.y_srf, /xs, /ynoz, ytit='!6Y!dSRF !n [arcsec]',chars=1.4
utplot, data.utc, data.z_srf, /xs, /ynoz, ytit='!6Z!dSRF !n [arcsec]',chars=1.4

print,"End-to-end processing test..."
out_dir = getenv('SAS_OUT_DIR')
cal_factor = 1.10   ; starting value, roughly OK for 2021 data
process_SAS_data, data_dir + in_file, out_dir + 'L2_SAS_test_new.fits', calib_file, simu_data_file, aperfile, cal_factor=cal_factor
