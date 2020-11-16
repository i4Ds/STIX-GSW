;+
; :Description:
;    Read and accumulate counts from these files
;    solo_L1_stix-sci-xray-l1-1169781776_20200523T055200-20200523T065200_V01_53410.fits
;    solo_L1_stix-sci-xray-l1-1169843728_20200523T093816-20200523T111416_V01_49201.fits
;    solo_L1_stix-sci-xray-l1-1169870352_20200523T111417-20200523T125017_V01_49202.fits
;    solo_L1_stix-sci-xray-l1-1169895952_20200523T125017-20200523T142617_V01_49203.fits
;    solo_L1_stix-sci-xray-l1-1169922576_20200523T142617-20200523T160217_V01_49204.fits
;    solo_L1_stix-sci-xray-l1-1169949200_20200523T160217-20200523T173817_V01_49205.fits
;    solo_L1_stix-sci-xray-l1-1169974800_20200523T173817-20200523T191417_V01_49206.fits
;    solo_L1_stix-sci-xray-l1-1170001424_20200523T191417-20200523T205017_V01_49207.fits
;    solo_L1_stix-sci-xray-l1-1170027024_20200523T205017-20200523T222617_V01_49208.fits
;    solo_L1_stix-sci-xray-l1-1170053648_20200523T222617-20200524T000217_V01_49209.fits
;    solo_L1_stix-sci-xray-l1-1170211344_20200524T000217-20200524T013817_V01_49210.fits
;    solo_L1_stix-sci-xray-l1-1170236944_20200524T013817-20200524T031417_V01_49211.fits
;    solo_L1_stix-sci-xray-l1-1170263568_20200524T031417-20200524T045017_V01_49212.fits
;    solo_L1_stix-sci-xray-l1-1170289168_20200524T045017-20200524T062617_V01_49213.fits
;    solo_L1_stix-sci-xray-l1-1170315792_20200524T062617-20200524T080217_V01_49214.fits
;    solo_L1_stix-sci-xray-l1-1170327568_20200524T070817-20200524T083417_V01_49216.fits
;    solo_L1_stix-sci-xray-l1-1170342416_20200524T080217-20200524T093759_V01_49215.fits
;    solo_L1_stix-sci-xray-l1-1170367760_20200524T093700-20200524T112609_V01_53411.fits
;    solo_L1_stix-sci-xray-l1-1170367760_20200524T112609-20200524T131519_V01_53412.fits
;    solo_L1_stix-sci-xray-l1-1170367760_20200524T131519-20200524T133659_V01_53413.fits;
;    
;    Usage:
;    IDL> out = stx_crab_accumulator('./crab', energy_range = [6,20])
;    Number of matching files           20
;    IDL> help, out
;    OUT             STRUCT    = -> <Anonymous> Array[30, 5467]
;    IDL> help, out,/st
;    ** Structure <16357fa0>, 9 tags, length=72, data length=58, refs=1:
;    DET_INDEX       INT              0
;    UT              DOUBLE      1.3062163e+009
;    TIMEDEL         FLOAT           19.1000
;    E_MIN           DOUBLE           6.0000000
;    E_HIGH          DOUBLE           20.000000
;    COUNTS          FLOAT     Array[4]
;    CRAB_X          FLOAT          0.000000
;    CRAB_Y          FLOAT          0.000000
;    ;    GRID_PHASE      FLOAT          0.000000
;    IDL> help, out
;    OUT             STRUCT    = -> <Anonymous> Array[30, 5467]
;    The data are organized by Caliste (det_id) and then by time 
;    The time and timedel are repeated for every Caliste for convenience
;    IDL> help, out[1,0]
;    ** Structure <16357fa0>, 9 tags, length=72, data length=58, refs=2:
;    DET_INDEX       INT              1
;    UT              DOUBLE      1.3062163e+009
;    TIMEDEL         FLOAT           19.1000
;    E_MIN           DOUBLE           6.0000000
;    E_HIGH          DOUBLE           20.000000
;    COUNTS          FLOAT     Array[4]
;    CRAB_X          FLOAT          0.000000
;    CRAB_Y          FLOAT          0.000000
;    GRID_PHASE      FLOAT          0.000000
;    IDL> help, out[0,0]
;    ** Structure <16357fa0>, 9 tags, length=72, data length=58, refs=2:
;    DET_INDEX       INT              0
;    UT              DOUBLE      1.3062163e+009
;    TIMEDEL         FLOAT           19.1000
;    E_MIN           DOUBLE           6.0000000
;    E_HIGH          DOUBLE           20.000000
;    COUNTS          FLOAT     Array[4]
;    CRAB_X          FLOAT          0.000000
;    CRAB_Y          FLOAT          0.000000
;    GRID_PHASE      FLOAT          0.000000
;    
; :Params:
;    crab_data_dir - required, directory with the data files to be read
;
; :Keywords:
;    energy_range - select counts within this range. If your energy_range is out
;    of the download range the energy_range will be truncated to the data range
;
; :Author: rschwartz70@gmail.com nov 2020
;-
function stx_crab_accumulator, crab_data_dir, energy_range = energy_range 

  default, energy_range, [6., 28]
  files = file_search( crab_data_dir, 'solo_L1_stix-sci-xray-l1-*.fits', count=nfiles)
  print, 'Number of matching files ', nfiles
  ;get the control structure for the first file, energy_bin_mask will be the same for all
  control = mrdfits( files[0], 1, /silent)
  ;only these energies in the files
  energy_bin_mask = control.ENERGY_BIN_MASK
  active_energy_bin = where( energy_bin_mask )
  ;find the total number of records
  nreci = intarr( nfiles )
  for ifl = 0, nfiles-1 do nreci[ifl] = n_elements( mrdfits( files[ ifl ], 2, /silent) )
  nreci_sum = [0L,long( total(/cum, nreci))]
  nrec  = last_item( nreci_sum )
  ;make the output structure
  result = replicate( { det_index: 0, ut: 0.0d0, timedel: 0.0, e_min: 0.0, e_high: 0.0, $
    counts: fltarr(4), crab_x: 0.0, crab_y: 0.0, grid_phase: 0.0}, 30, nrec)
    
  ;get the energy range to use
  energy = mrdfits(files[0], 3, /silent)
  energy_used = energy[ active_energy_bin ]
  ixel = value_closest( energy_used.e_low, energy_range[0], value= e_low)
  ixeh = value_closest( energy_used.e_high, energy_range[1], value = e_high)
  energy_range = [e_low, e_high]
  ix_energy    = [ixel, ixeh] + active_energy_bin[0]
  det_mask = indgen(32)
  remove, [8,9], det_mask ;don't use cfl or bkg det
  ndet = 30
  result = replicate( { det_index: 0, ut: 0.0d0, timedel: 0.0, e_min: energy_range[0], e_high: energy_range[1], $
    counts: fltarr(4), crab_x: 0.0, crab_y: 0.0, grid_phase: 0.0}, 30, nrec)
  result.det_index = reproduce( det_mask,nrec)
  jrec = 0L
  for ifl = 0, nfiles -1 do begin
    hdr = headfits( files[ ifl ])
    ut_base = anytim( fxpar( hdr,'date_beg')) ;convert to dbl since 1-jan-1979
    data = mrdfits( files[ ifl],2,/silent)
    ir = nreci_sum[ ifl]*ndet + lindgen( nreci[ifl]*ndet)
    
    ut = ut_base + data.time
    result_ifl = reform( result[ir], 30, nreci[ifl],/over)
    result_ifl.ut = transpose( reproduce( ut, 30))
    result_ifl.timedel = transpose( reproduce( data.timedel, 30))
    counts = data.counts
    ;apply det_mask
    counts = counts[ ix_energy[0]:ix_energy[1], indgen(8), det_mask, *]
    tcounts = total( counts, 1)
    ;this is the column sums for each det, 4 columns each
    tcolumns = tcounts[0:3,*,*] + tcounts[4:7, *, *]
    result_ifl.counts = tcolumns
    result[ir] = result_ifl
    
  endfor




  return, result
end