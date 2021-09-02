; SAS_test.pro
; A short sample of commands to test that the SAS Pipeline procedures are running as expected.
; 
; F. Schuller (AIP Potsdam, Germany) -  2021-08-06
; 
@configure    ; this defines the I/O directories and loads the relevant SPICE kernels

print,"Reading L1 data file..."
in_file = "solo_L1_stix-hk-maxi_20210401_V01.fits"
data = read_hk_data(in_file, quiet=0)
show_info, data

print,"Calibrating data..."
cal_factor = 1.10   ; roughly OK for 2021 data
calib_sas_data, data, factor=cal_factor

print,"Plotting the signals..."
plot4sig, data

print,"Computing aspect solution..."
derive_aspect_solution, data
!p.multi = [0,1,2]
utplot, data.utc, data.y_srf, /xs, /ynoz, ytit='!6Y!dSRF !n [arcsec]',chars=1.4
utplot, data.utc, data.z_srf, /xs, /ynoz, ytit='!6Z!dSRF !n [arcsec]',chars=1.4

print,"End-to-end processing test..."
process_SAS_data, in_file, cal_factor=cal_factor, outfile='L2_SAS_test.fits'
