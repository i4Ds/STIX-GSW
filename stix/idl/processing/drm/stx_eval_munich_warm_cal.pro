
;+
; :Description:
;    Identify the narrow line spectra in the warm cal Munich data and fit the main peak
;    Not all detectors, pixels, and runs qualify. The criteria for fitting for all runs turns out
;    to be those spectra with peaks gt 50 counts.  This is not a normal calibration run and should not
;    be treated as such. It requires customization. In flight calibrations should be small displacements from
;    their previous calibrations. This fits the peaks with a simple gaussian and adds the fitted peak to the
;    input Spectra structure. Write the main results of each spectrum for each pixel, detector, run into a series
;    of csv files bearing the name of the run 0-20
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run00.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run01.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run02.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run03.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run04.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run05.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run06.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run07.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run08.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run09.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run10.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run11.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run12.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run13.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run14.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run15.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run16.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run17.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run18.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run19.csv"
;    "C:\ssw\soft\stix_ssm\munich_cal_spectra_run20.csv"
;:Params: 
;     Files - files written in the working directory
;:Returns: Only FILES
;
;
; :Author: 26-nov-2019, rschwartz70@gmail.com
;-
pro stx_eval_munich_warm_cal, files = files


  restore,'munich_calibration_spectra.sav',/ver
  help, asw_ql_calibration_spectrum
  stx_read_elut, gain, offset
  e3181 = fltarr(2, 12, 32)
  e3181[0,*,*] = 30.85/gain +offset
  e3181[1,*,*] = 81./gain +offset

  nrun = asw_ql_calibration_spectrum.count()
  files = {all_data: 'munich_cal_spectra_300_550ADC.ps', first_cut: 'first_cut_pk_ge30.ps', fitted:'fitted_pk_ge50.ps', $
    all_csv: strarr( nrun ), best_csv: 'munich_cal_spectra_fitted_results.csv'}
  ss = lonarr( 1024, 12,32, nrun)
  dim13 = (ss.dim)[1:3]
  spectra = replicate( {data: fltarr(250), nch31:0.0, nch81:0.0, ip:0, id:0, irun:0, pixel_mask: bytarr(12), detector_mask: bytarr(32),$
    ipk:0, vpk:0.0, totsp:0.0}, dim13)
  for irun = 0,nrun-1 do begin
    ss[0, 0, 0, irun] = stx_calibration_data_array( asw_ql_calibration_spectrum[irun])

  endfor
  ix = indgen( 250 ) + 300
  nix = ix.length
  nspec = product( dim13 )
  spectra.data = ss[ix, *, *, *]
  spectra.irun = rebin( indgen( 1, 1, nrun), 12, 32, nrun)
  for irun = 0,nrun-1 do for idet = 0, 31 do for ipix = 0, 11 do  begin
    spectra[ipix, idet, irun].pixel_mask = asw_ql_calibration_spectrum[irun].subspectra[0].pixel_mask
    spectra[ipix, idet, irun].detector_mask = asw_ql_calibration_spectrum[irun].subspectra[0].detector_mask
    spectra[ipix, idet, irun].ip = ipix
    spectra[ipix, idet, irun].id = idet
  endfor
  spectra.nch31 = reform( reproduce( e3181[0,*,*], nrun))
  spectra.nch81 = reform( reproduce( e3181[1,*,*], nrun))
  spectra.totsp = total( spectra.data, 1 )
  spectra.vpk   = max( spectra.data, dim=1, cc )
  vv_offset     = max( 0L * spectra.data, dim=1, cc_offset)
  spectra.ipk   = cc - cc_offset ;these peaks are the indices offset from the first index for each spectrum

  sps,/land,/color
  device, filename= files.all_data
  !p.multi = [0, 8, 8]
  for irun = 0, nrun-1 do for idet = 0, 31 do for ipix = 0,7 do  begin
    sp = spectra[ipix, idet, irun]
    plot, ix, sp.data, xtickint=100, xcharsize=1., psym=10, title= 'p:'+strtrim(sp.ip,2)+' d:'+strtrim(sp.id,2)+$
      ' run:'+strtrim( sp.irun, 2)

  endfor
  device,/cl
  sps,/land
  device, filename = 'Good_spectra.ps'
  qgd = where( abs( spectra.totsp -600 ) lt 400, nqgd)
  for iq = 0L, nqgd-1 do begin
    sp = spectra[qgd[iq]]
    plot, ix, sp.data, xtickint=100, xcharsize=1., psym=10, title= 'p:'+strtrim(sp.ip,2)+' d:'+strtrim(sp.id,2)+$
      ' run:'+strtrim( sp.irun, 2)

  endfor
  device,/close

  sps,/land
  device, filename = files.first_cut
  !p.multi = [0, 8, 8]
  z = where( abs( spectra.totsp -600 ) lt 400 and spectra.vpk ge 30, nz)
  spz = spectra[z]
  for iz= 0L, nz-1 do begin
    sp = spz[ iz ]
    plot, ix, sp.data, xtickint=100, xcharsize=1., psym=10, title= 'p:'+strtrim(sp.ip,2)+' d:'+strtrim(sp.id,2)+$
      ' run:'+strtrim( sp.irun, 2)

  endfor
  device,/cl

  !p.multi = 0

  set_x
  spectra = reform(/over, spectra, 384, nrun)
  ;add a fitted line at the peak for quality spectra and plot these
  stx_eval_munich_warm_cal_pk50, spectra, threshold = 50, filename = files.fitted
  ;  IDL> chkarg,'write_csv
  ;  % CHKARG: recalling write_csv.pro from memory
  ;  ---- Module: write_csv.pro
  ;  ---- From:   C:\Program Files\exelis\IDL85\lib\
  ;  ---> Call: function write_csv_convert, data
  ;  ---> Call: pro write_csv, Filename, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, $
  ;    HEADER=header, TABLE_HEADER=tableHeader
  ;  IDL> help, spectra
  ;  SPECTRA         STRUCT    = -> <Anonymous> Array[384, 21]
  ;  IDL> help, spectra,/st
  ;  ** Structure <21048450>, 11 tags, length=1068, data length=1068, refs=3:
  ;  DATA            FLOAT     Array[250]
  ;  NCH31           FLOAT           335.850
  ;  NCH81           FLOAT           452.812
  ;  IP              INT              0
  ;  ID              INT              0
  ;  IRUN            INT              0
  ;  PIXEL_MASK      BYTE      Array[12]
  ;  DETECTOR_MASK   BYTE      Array[32]
  ;  IPK             INT              0
  ;  VPK             FLOAT          0.000000
  ;  TOTSP           FLOAT          0.000000
  ;table_header = tag_names( spectra)
  results = replicate( { pixel: 0, detector:0, mask: 0b, $
    nch31: 0.0, pkchan: 0.0, diffpk: 0.0,  pkvalue: 0.0, gauss_pk:0.0, diffgpk:0.0, total: 0.0}, 384, nrun)
  results.pixel = spectra.ip
  results.detector = spectra.id
  rmask = intarr( 384, nrun )
  for i =0,384L* nrun-1 do rmask[i] = spectra[i].pixel_mask[spectra[i].ip] * spectra[i].detector_mask[spectra[i].id]
  results.mask = rmask
  results.nch31 = spectra.nch31 
  results.pkchan = spectra.ipk + 300.0
  results.gauss_pk = spectra.gauss_pk
  results.pkvalue = spectra.vpk
  results.total = spectra.totsp
  results.diffpk = results.nch31 - results.pkchan
  has_gauss_pk = where( results.gauss_pk gt 0.0)
  results[has_gauss_pk].diffgpk = (results.nch31 - results.gauss_pk)[has_gauss_pk]
  all_csv = strarr(nrun)
  for i = 0, nrun-1 do begin
    all_csv[i] = 'munich_cal_spectra_run'+strmid(strtrim(i+100,2),1,2)+'.csv'
    write_csv, all_csv[i], results[*,i], header = tag_names(results)
  endfor
  files.all_csv = all_csv
  write_csv, files.best_csv, results[ has_gauss_pk ], header = tag_names(results)  


end