;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_transmission
;
; :description:
;
;    This procedure calculates the transmission probality of photons at specified energy range from the front entrance to
;    the detector
;
;
; :categories:
;    response
;
; :params:
;
;    ein : in, required, type="fltarr"
;             an array of energies at which to calculate the transmission
;
;    det_mask :in, type="fltarr", default="intarr(32)+1"
;              An array of detector indices to use
;
; :keywords:
;
;    attenuator : in, type="boolean", default="0"
;               If set include transmission through aluminium attenuator
;
;    xcom : in, type="boolean", default="0"
;               If set calculate transmission using IDL xcom rather than supplied tables
;
;    transmission_table : in, type="string", default="stix_transmission_highres_20210303.csv'"
;              path to csv file of transmission table to use
;
;    sbo : in, type="boolean", default="0"
;               if set use SolarBlack (Oxygen) composition rather than SolarBlack (Carbon)
;
; :returns:
;   fltarr with the transmission fraction at the specified energies
;
;
; :history:
;    25-Jan-2021 - ECMD (Graz), initial release
;    12-Mar-2021 - ECMD (Graz), added xcom keyword by default now uses file stix_transmission_highres_20210303.csv
;                               to calculate transmission
;    25-Jan-2022 - ECMD (Graz), attenuator and transmission_table keywords added
;    22-Feb-2022 - ECMD (Graz), documented
;    29-Jun-2022 - ECMD (Graz), updated to call transmission table stix_transmission_highres_20220621.csv which includes
;                               alloys to describe the Be window and Al attenuator. Attenuator transmission is included in
;                               standard table so a separate call to a component separated table is no longer needed.
;   10-May-2023 - ECMD (Graz),  direct xcom calculation updated to use Be and Al alloys                       
;
;-
function stx_transmission, ein, det_mask, attenuator = attenuator, xcom = xcom, transmission_table = transmission_table, sbo = sbo, verbose = verbose

  default, det_mask, intarr(32)+1
  default, xcom, 0
  default, attenuator, 0

  ;TODO - option for grid covers
  idx_det = where(det_mask eq 1, count_det)

  ;if set calculate the transmission factors directly using xsec
  if keyword_set(xcom) then begin

    emin = ein

    ; conversion factors to cm
    mil = 0.00254d0
    angstrom = 1d-8
    mm = .1d0
    nm = 1d-7

    default, type, 'AB'
    costheta = 1.0d0

    ;    ;Al (Z=13)  Al  13: 1.0 2.7 - Original pure Al transmission parameters kept for reference 
    ;    rho_al = 2.7d0
    ;    tr_al =   (xsec(emin, 13,type,/cm2perg , /use_xcom , error=error) * rho_al/costheta)

    ; alloy transmission information from STIXCore/stixcore/calibration/transmission.py see https://github.com/i4Ds/STIXCore/pull/240
    rho_al_alloy = 2.8
    tr_al_alloy =( (xsec(emin, (Element2Z('Al'))[0],type,/cm2perg , /use_xcom )*0.89345 + $
      xsec(emin, (Element2Z('Si'))[0], type, /cm2perg, /use_xcom )*0.002   + $
      xsec(emin, (Element2Z('Fe'))[0], type, /cm2perg, /use_xcom )*0.0025  + $
      xsec(emin, (Element2Z('Cu'))[0], type, /cm2perg, /use_xcom )*0.016   + $
      xsec(emin, (Element2Z('Mn'))[0], type, /cm2perg, /use_xcom )*0.0015  + $
      xsec(emin, (Element2Z('Mg'))[0], type, /cm2perg, /use_xcom )*0.025   + $
      xsec(emin, (Element2Z('Cr'))[0], type, /cm2perg, /use_xcom )*0.0023  + $
      xsec(emin, (Element2Z('Ni'))[0], type, /cm2perg, /use_xcom )*0.00025 + $
      xsec(emin, (Element2Z('Zn'))[0], type, /cm2perg, /use_xcom )*0.056   + $
      xsec(emin, (Element2Z('Ti'))[0], type, /cm2perg, /use_xcom )*0.001) * rho_al_alloy/costheta)


    ;Be (z=4) Be  4: 1.0  1.85 - Original pure Be transmission parameters kept for reference 
    ;    rho_be =  1.85d0
    ;    tr_be =  (xsec(emin, 4,type,/cm2perg,  /use_xcom, error=error) * rho_be/costheta)

    rho_be_alloy = 1.84
    tr_be_alloy = ((xsec(emin, (Element2Z('Al'))[0],type,/cm2perg , /use_xcom )*0.0005 + $
      xsec(emin, (Element2Z('Be'))[0], type,/cm2perg, /use_xcom )*0.9974  + $
      xsec(emin, (Element2Z('C'))[0] , type,/cm2perg, /use_xcom )*0.00075 + $
      xsec(emin, (Element2Z('Fe'))[0], type,/cm2perg, /use_xcom )*0.00065 + $
      xsec(emin, (Element2Z('Mg'))[0], type,/cm2perg, /use_xcom )*0.0004  + $
      xsec(emin, (Element2Z('Si'))[0], type,/cm2perg, /use_xcom )*0.0003) * rho_be_alloy/costheta)

    ;TODO - convert other components to using Element2Z for clarity.   

    ;Kapton C22H10N2O5  1: 0.026362, 6: 0.691133, 7: 0.073270, 8: 0.209235  1.43
    rho_kapton  = 1.43d0
    tr_kapton =   ((xsec(emin, 1,type,/cm2perg, /use_xcom, error=error)*0.026362d0 + xsec(emin, 6,type,/cm2perg, /use_xcom, error=error)*0.691133d0 $
      +  xsec(emin, 7,type,/cm2perg, error=error)*0.073270d0 + xsec(emin, 8,type,/cm2perg, error=error)*0.209235d0  ) * rho_kapton/costheta)

    ;Mylar  C10H8O4 1: 0.041959, 6: 0.625017, 8: 0.333025 1.4
    rho_mylar  = 1.4d0
    tr_mylar =   ((xsec(emin, 1,type,/cm2perg, /use_xcom, error=error)*0.041959d0 + xsec(emin, 6,type,/cm2perg, /use_xcom, error=error)*0.625017d0 $
      +  xsec(emin, 8,type,/cm2perg, error=error)*0.333025d0 ) * rho_mylar/costheta)

    ;SolarBlack (Carbon)    1: 0.002 8: 0.415, 20: 0.396, 15: 0.187 3.2
    rho_sb = 3.2
    tr_sbc =    ((xsec(emin, 1,type,/cm2perg, /use_xcom, error=error)*0.002d0 + xsec(emin, 8,type,/cm2perg, /use_xcom, error=error)*0.415d0 $
      +  xsec(emin, 20,type,/cm2perg, /use_xcom, error=error)*0.396d0 + xsec(emin, 15,type,/cm2perg, /use_xcom, error=error)* 0.187d0) * rho_sb/costheta)


    ;SolarBlack (Oxygen)  4C2CaP  8: 0.301 20: 0.503 15: 0.195  3.2
    tr_sbo =   ((  xsec(emin, 8,type,/cm2perg, error=error)*0.301 $
      +  xsec(emin, 20,type,/cm2perg, /use_xcom, error=error)*0.503 + xsec(emin, 15,type,/cm2perg, /use_xcom, error=error)* 0.195) * rho_sb/costheta)

    tr_sb = keyword_set(sbo) ? tr_sbo : tr_sbc

    ;Tellurium dioxide TeO2  51: 0.7995, 8: 0.2005 5.670
    rho_dl = 5.670
    tr_dl =  (  (xsec(emin, 51,type,/cm2perg, /use_xcom, error=error)*0.7995 + xsec(emin, 8,type,/cm2perg, /use_xcom, error=error)*0.2005 ) * rho_dl/costheta)

    ;Front window Compound  -
    ;- SolarBlack 0.005 mm
    ;-  Be  2 mm
    fw = (1.d0/exp( (tr_be_alloy)*(2d0*mm) ))*(1.d0/exp( (tr_sb)*(0.005d0*mm)) )

    ;Rear window  Be  1 mm
    rw = (1.d0/exp((tr_be_alloy)*(1d0*mm)))

    ;Fine grid covers: Kapton  4 x 2 mils
    grid_covers = 1.d0/exp((tr_kapton)*(4*2*mil))

    ;DEM Entrance: Kapton  2 x 3 mils
    dem_entrance = 1.d0/exp((tr_kapton)*(6*mil))

    ; Attenuator: Al 0.6 mm
    att = 1.d0/exp((tr_al_alloy)*(0.6*mm))

    ;
    ;MLI  Compound  -
    ;- Outer layer  Al  1000 Å
    ;- Outer layer  Kapton  3 mils
    ;- Spacer x 21  Dacron B4A  TBD
    ;- Reflector x 40 Al  1000 Å
    ;- Reflector x 20 Mylar 0.25 mils
    ;- Outer layer  Mylar 3 mils
    ;- Outer layer  Al  1000 Å
    ;
    ; Al = 42 x 1000 Å
    ; Mylar = 0.25 x 20 + 3 mils
    ; Kapton = 3 mils
    ; Dacron = not included
    ;
    mli = (1d0/exp( (tr_al_alloy)*(42d0 * 1000.d0*angstrom) )) * ( 1.d0/exp( (tr_kapton)*(3d0*mil)  )) * (1d0/exp( (tr_mylar) *(20d0*.25d0*mil + 3d0*mil)))

    ;Calibration Foil   -
    ;-  AL  4 x 1000 Å
    ;-  Kapton  4 x 2 mils
    cal_foil = (1d0/exp( (tr_al_alloy)*(4d0 * 1000.d0*angstrom) )) * ( 1.d0/exp( (tr_kapton)*(8*mil) ))

    ;Dead Layer: TeO2  392 n
    dead_layer = 1.d0/exp((tr_dl)*(392*nm))


    tot_coarse = fw*rw*dem_entrance*mli*cal_foil*dead_layer
    tot_fine = tot_coarse*grid_covers

    idx_covered_grids = [10,11,12,16,17,18]

    tot_detector = (fltarr(32)+1.)##tot_coarse
    for i=0, n_elements(idx_covered_grids)-1 do  tot_detector[*, idx_covered_grids[i]]  = tot_fine


    tot = total(tot_detector[*,idx_det]/count_det,2)


    if attenuator then begin
      tot *= att

    endif

  endif else begin
    ;otherwise use the transmission values from the CSV file
    if file_exist( transmission_table ) then begin
      transmission_table = transmission_table
    endif else begin

      transmission_table_sbc =  loc_file( 'stix_transmission_highres_20220621.csv', path = getenv('STX_GRID'))
      transmission_table_sbo =  loc_file( 'stix_transmission_highres_alt_20210826.csv', path = getenv('STX_GRID'))

      transmission_table = keyword_set(sbo) ? transmission_table_sbo : transmission_table_sbc

    endelse

    transmission = read_csv(transmission_table, head = header)

    energy = transmission.(0)

    tot = fltarr(n_elements(energy))

    for i =0, count_det-1 do tot += transmission.(idx_det[i]+1)/count_det

    if attenuator then begin

      att = transmission.(33)

      tot *= att
    endif


    if  ~array_equal(energy, ein) then begin
      tot=10^(interpol(alog10(tot),alog10(energy),alog10(ein)))
    endif


  endelse


  return, tot


end
