function stix_transmission, ein, xcom = xcom

  default, xcom, 0
  ;TODO - option for grid covers

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

    ;Tellurium dioxide TeO2  51: 0.7995, 8: 0.2005 5.670
    rho_dl = 5.670
    tr_dl =  (  (xsec(emin, 51,type,/cm2perg, /use_xcom, error=error)*0.7995 + xsec(emin, 8,type,/cm2perg, /use_xcom, error=error)*0.2005 ) * rho_dl/costheta)

    ;Front window Compound  -
    ;- SolarBlack 0.005 mm
    ;-  Be  2 mm
    fw = (1.d0/exp( (tr_be)*(2d0*mm) ))*(1.d0/exp( (tr_sbo)*(0.005d0*mm) ) )

    ;Rear window  Be  1 mm
    rw = (1.d0/exp((tr_be)*(1d0*mm)))

    ;Fine grid covers Kapton  4 x 2 mils - not incuded

    ;DEM Entrance Kapton  2 x 3 mils
    dem_entrance = 1.d0/exp((tr_kapton)*(6*mil))

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

    ;Dead Layer TeO2  392 n
    dead_layer = 1.d0/exp((tr_dl)*(392*nm))


    tot = fw*rw*dem_entrance*mli*cal_foil*dead_layer


  endif else begin
    ;otherwise use the transmission values from the CSV file

    transmission = read_csv(loc_file( 'stix_trans_by_component.csv', path = getenv('STX_GRID') ))

    front_window = transmission.FIELD1
    rear_window = transmission.FIELD2
    grid_covers = transmission.FIELD3
    dem = transmission.FIELD4
    attenuator = transmission.FIELD5
    mli = transmission.FIELD6
    calibration_foil = transmission.FIELD7
    dead_layer = transmission.FIELD8
    energy = transmission.FIELD9

    tot = front_window*rear_window*dem*mli*calibration_foil*dead_layer

    if  ~array_equal(energy, ein) then begin
      tot=10^(interpol(alog10(tot),alog10(energy),alog10(ein)))
    endif


  endelse


  return, tot


end



