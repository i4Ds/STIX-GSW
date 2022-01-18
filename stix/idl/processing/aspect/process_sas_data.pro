;+
; Description :
;   Procedure to read STIX L1 housekeeping data, process the aspect data and write the result L2 data to a file.
;
; Syntax      : 
;    process_SAS_data, infile [, calibfile=calibfile, cal_factor=cal_factor, outfile=outfile, /quiet ]
;    
; Inputs      :
;     infile  = input file name, including full absolute path
;     outfile = output file name, including full absolute path
;   calibfile = name of the file with calibration parameters (gains and bias values), including full absolute path
;   simu_data_file = name of the file with simulated data, including full absolute path
;
; Output      : None.
;
; Optional keyword:
;     cal_factor = an extra calibration factor to be applied (multiplied) to all signals; default = 1.0
;     quiet      = if set, don't display information messages
;
; History   :
;   2021-06-21 - F. Schuller (AIP), created
;   2022-01-18 - FSc: added argument aperfile, needed to compute scaling factor
;
;-

pro process_SAS_data, infile, outfile, calibfile, simu_data_file, aperfile, cal_factor=cal_factor, quiet=quiet
  data = read_hk_data(infile, quiet=quiet)
  calib_sas_data, data, calibfile, factor=cal_factor
  auto_scale_sas_data, data, simu_data_file, aperfile
  derive_aspect_solution, data, simu_data_file
  write_aspect_solution, data, outfile, quiet=quiet
end
