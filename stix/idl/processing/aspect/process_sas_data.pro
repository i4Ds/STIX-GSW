;+
; Description :
;   Procedure to process aspect HK data contained in an array of STX_ASPECT_DTO structures. The results
;   (= aspect solution) are stored in the Y_SRF and Z_SRF attributes of that structure.
;
; Syntax      : 
;    process_SAS_data, data, calibfile, simu_data_file, aperfile [, cal_factor=cal_factor]
;    
; Inputs      :
;   data      = an array of STX_ASPECT_DTO structures
;   calibfile = name of the file with calibration parameters (gains and bias values), including full absolute path
;   simu_data_file = name of the file with simulated data, including full absolute path
;   aperfile  = name (with absolute path) of the file with description of apertures geometry
;   
; Output      : None.
;
; Optional keyword:
;     cal_factor = an extra calibration factor to be applied (multiplied) to all signals; default = 1.0
;
; History   :
;   2021-06-21 - F. Schuller (AIP), created
;   2022-01-18 - FSc: added argument aperfile, needed to compute scaling factor
;   2022-01-28, FSc: removed reading and writing FITS files, only manipulate STX_ASPECT_DTO structure
;
;-

pro process_SAS_data, data, calibfile, simu_data_file, aperfile, cal_factor=cal_factor
  default, cal_factor, 1.

  calib_sas_data, data, calibfile, factor=cal_factor
  auto_scale_sas_data, data, simu_data_file, aperfile
  derive_aspect_solution, data, simu_data_file, /interpol_r, /interpol_xy
end
