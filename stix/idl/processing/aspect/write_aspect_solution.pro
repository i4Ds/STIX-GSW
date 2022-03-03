;+
; Description :
;   Procedure to write SAS L2 data to a file
;
; Syntax      : write_aspect_solution, data, filename [, /quiet]
;
; Inputs      : 
;     data      = a data structure containing timestamps, signal, input FITS header and derived aspect solution
;     filename  = output file name, including full absolute path
;
; Output      : None.
; 
; Optional keyword:
;     quiet     = if set, don't display information messages
;
; History   :
;   2021-06-17 - FSc: initial version
;   2021-08-09 - FSc: renamed from write_L2_data to write_aspect_solution
;   2021-11-15 - FSc: removed common block "config"
;
; Example:
;   write_aspect_solution, data, '/path/to/L2_files/aspect_20210101.fits'
;
;-

pro write_aspect_solution, data, filename, quiet=quiet

  if n_params() lt 2 then message,'  SYNTAX:  write_aspect_solution, data, filename [, /quiet]

  ; Test that output directory exists
  out_dir = file_dirname(filename)
  result = file_test(out_dir)
  if not result then begin
    message,"  ERROR: Directory "+out_dir+" not found."
  endif

  ; Update keywords with L2-relevant values
  primary = data.primary
  sxaddpar, primary, 'FILENAME', filename
  sxaddpar, primary, 'LEVEL', 'L2'
  get_utc, utc_now, /ccsds, /truncate
  sxaddpar, primary, 'DATE', utc_now
  
  ; Determine filenames that contain orbit and clock kernels
  list_sunspice_kernels, kern=klist, /quiet
  ker_orbit = ""  &  ker_clock = ""
  for i=0,n_elements(klist)-1 do begin
    tmp = strsplit(klist[i],"/",/extract)
    ker_name = tmp[-1]
    if strmatch(ker_name,"*solo_ANC_soc-orbit*") then ker_orbit = ker_name
    if strmatch(ker_name,"*sclk*") and not strmatch(ker_name,"*fict*") then ker_clock = ker_name
  endfor
  sxaddpar, primary, 'KERN_ORB', ker_orbit, " SPICE orbit kernel", before='HISTORY'
  sxaddpar, primary, 'KERN_CLK', ker_clock, " SPICE clock kernel", before='HISTORY'
  
  ; Add current version of the SAS pipeline to history
  sas_version = getenv('SAS_VERSION')
  sxaddhist, "Aspect data processed with SAS_pipeline ver. " + sas_version, primary

  ; Ready to create the output file
  fxwrite, filename, primary
  fxbhmake, header, n_elements(data.utc), 'DATA'
  fxbaddcol, col1, header, data.utc[0], 'TIME', 'UTC'
  fxbaddcol, col2, header, data.y_srf[0], 'Y_SRF', tunit='arcsec'
  fxbaddcol, col3, header, data.z_srf[0], 'Z_SRF', tunit='arcsec'
  fxbcreate, unit, filename, header
  fxbwritm, unit, ['TIME','Y_SRF','Z_SRF'], data.utc, data.y_srf, data.z_srf
  fxbfinish, unit

  if not keyword_set(quiet) then $
    print, "L2 data successfully written to file: " + filename
  
end
