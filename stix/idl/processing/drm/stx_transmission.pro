;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_transmission
;
; :description:
;    This procedure saves a property file at given location. The properties... etc.
;
;
; :categories:
;    response
;
; :params:
;    param1 : in, required, type="string"
;             a required string input
;    param2 :
;
;
; :keywords:
;    keyword1 : in, type="float", default="1.0"
;               an output float value
;    keyword2 :
;
;
; :returns:
;    strarr[10, 15] with text in it
;
; :examples:
;    result = 'hello', /verbose
;
; :history:
;    31-Jul-2017 - ECMD (Graz), initial release
;
;-
function stx_transmission, ein, det_mask, attenuator = attenuator, xcom = xcom, transmission_table = transmission_table, sbo = sbo, verbose = verbose

  default, det_mask, intarr(32)+1
  default, xcom, 0
  default, attenuator, 0

  ;TODO - option for grid covers
  idx_det = where(det_mask eq 1, count_det)

  ;if set cacluate the transmission factors directly using xsec
  if keyword_set(xcom) then begin

    emin = ein

    ; conversion factors to cm
    mil = 0.00254d0
    angstrom = 1d-8
    mm = .1d0
    nm = 1d-7

    default, type, 'AB'
    costheta = 1.0d0

    ;Al (Z=13)  Al  13: 1.0 2.7
    rho_al = 2.7d0
    tr_al =   (xsec(emin, 13,type,/cm2perg , /use_xcom , error=error) * rho_al/costheta)


    ;Be (z=4) Be  4: 1.0  1.85
    rho_be =  1.85d0
    tr_be =  (xsec(emin, 4,type,/cm2perg,  /use_xcom, error=error) * rho_be/costheta)

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
    fw = (1.d0/exp( (tr_be)*(2d0*mm) ))*(1.d0/exp( (tr_sb)*(0.005d0*mm)) )

    ;Rear window  Be  1 mm
    rw = (1.d0/exp((tr_be)*(1d0*mm)))

    ;Fine grid covers: Kapton  4 x 2 mils
    grid_covers = 1.d0/exp((tr_kapton)*(4*2*mil))

    ;DEM Entrance: Kapton  2 x 3 mils
    dem_entrance = 1.d0/exp((tr_kapton)*(6*mil))

    ; Attenuator: Al 0.6 mm
    att = 1.d0/exp((tr_al)*(0.6*mm))

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
    ; Dacron = not incuded
    ;
    mli = (1d0/exp( (tr_al)*(42d0 * 1000.d0*angstrom) )) * ( 1.d0/exp( (tr_kapton)*(3d0*mil)  )) * (1d0/exp( (tr_mylar) *(20d0*.25d0*mil + 3d0*mil)))

    ;Calibration Foil   -
    ;-  AL  4 x 1000 Å
    ;-  Kapton  4 x 2 mils
    cal_foil = (1d0/exp( (tr_al)*(4d0 * 1000.d0*angstrom) )) * ( 1.d0/exp( (tr_kapton)*(8*mil) ))

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

      transmission_table_sbc =  loc_file( 'stix_transmission_highres_20210303.csv', path = getenv('STX_GRID'))
      transmission_table_sbo =  loc_file( 'stix_transmission_highres_alt_20210826.csv', path = getenv('STX_GRID'))

      transmission_table = keyword_set(sbo) ? transmission_table_sbo : transmission_table_sbc

    endelse

    transmission = read_csv(transmission_table, head = header)

    energy = transmission.(0)

    tot = fltarr(n_elements(energy))

    for i =0, count_det-1 do tot += transmission.(idx_det[i]+1)/count_det

    if attenuator then begin

      transmission_table_comp = loc_file( 'stix_transmission_by_component_highres_20210303.csv', path = getenv('STX_GRID'))
      transmission_components = read_csv(transmission_table_comp, head = header)

      ;TODO check attenuation is on same energy binning as other components

      att = transmission_components.(4)

      tot *= att
    endif


    if  ~array_equal(energy, ein) then begin
      tot=10^(interpol(alog10(tot),alog10(energy),alog10(ein)))
    endif


  endelse


  return, tot


end
