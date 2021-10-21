;+
; Description :
;   Procedure to read STIX L1 housekeeping data, process the aspect data and write the result L2 data to a file.
;
; Syntax      : 
;    process_SAS_data, infile [, calibfile=calibfile, cal_factor=cal_factor, outfile=outfile, /quiet ]
;    
; Inputs      : input file name
;
; Output      : None.
;
; Optional keyword:
;     cal_factor = 
;     outfile    = 
;     quiet      = if set, don't display information messages
;
; History   :
;   2021-06-21 - F. Schuller (AIP), created
;
; Example:
;   process_SAS_data, 'solo_L1_stix-hk-maxi_20210401_V01'
;
;-

pro process_SAS_data, infile, calibfile=calibfile, cal_factor=cal_factor, outfile=outfile, quiet=quiet
  data = read_hk_data(infile, quiet=quiet)
  calib_sas_data, data, calibfile=calibfile, factor=cal_factor
  derive_aspect_solution, data
  write_aspect_solution, data, filename=outfile, quiet=quiet
end
