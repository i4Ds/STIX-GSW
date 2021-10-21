FUNCTION stix_gtrans32_test_sep_2021,xy_flare,o_flare=o_flare,rel_f=rel_f,plot=plot

  ; function that reads grid table and calculates grid transmission for 32 subcollimators
  ; used for testing and finding issues

  ; for finest grids: only transmission without correction for internal shadowing

  ;input: xy_flare = position of flare in heliocentric coordinates as seen from Solar Orbiter
  ;

  ;output: grid transmission for each subcollimator with the usual labeling

  ; gtrans=stix_gtrans32_test([0,0.])



  ;read grid parameters
  ;grid_temp=ascii_template('grid_param_front.txt')
  ;save,grid_temp,filename='grid_temp.sav'
  restore,loc_file( 'grid_temp.sav', path = getenv('STX_VIS_DEMO') )
  fff=read_ascii(loc_file( 'grid_param_front.txt', path = getenv('STX_VIS_DEMO') ),temp=grid_temp)
  rrr=read_ascii(loc_file( 'grid_param_rear.txt', path = getenv('STX_VIS_DEMO') ),temp=grid_temp)

  
  ;assumes pointing to solar center (to be corrected with aspect data in the future)
  ;correct for pixel look direction
  ;Ewan will send definition of plus minus by email. for now I use the following
  ;xy_flare_stix=[-xy_flare(1),xy_flare(0)]
  
  ;;;;; Paolo Massa (September 2021): changed definition of 'xy_flare_stix' according to the relationship between
  ;;;;; the heliocentric coordinate system and the SXmap one
  xy_flare_stix=[xy_flare(1),-xy_flare(0)] 
  ;print,xy_flare
  ;print,xy_flare_stix

  ;radial
  r_flare=sqrt( total(xy_flare_stix^2) )
  ;angle from +y direction (definition used by Matej in grid table)
  ;o_flare=abs(asin(xy_flare_stix(1)/r_flare)/!pi*180)
  ;o_flare=90-abs(asin(xy_flare_stix(1)/r_flare)/!pi*180)
  ;new October 26

  ;;;;; Paolo Massa (September 2021): corrected the definition of 'o_flare'
  
;  if (xy_flare_stix(0) ge 0) AND (xy_flare_stix(1) ge 0) then o_flare=acos(xy_flare_stix(1)/r_flare)/!pi*180.
;  if (xy_flare_stix(0) ge 0) AND (xy_flare_stix(1) le 0) then o_flare=90+asin(abs(xy_flare_stix(1))/r_flare)/!pi*180.
;  if (xy_flare_stix(0) le 0) AND (xy_flare_stix(1) le 0) then o_flare=acos(abs(xy_flare_stix(1))/r_flare)/!pi*180.
;  if (xy_flare_stix(0) le 0) AND (xy_flare_stix(1) ge 0) then o_flare=90+asin(xy_flare_stix(1)/r_flare)/!pi*180.

  if (xy_flare_stix(0) ge 0) AND (xy_flare_stix(1) ge 0) then o_flare=acos(xy_flare_stix(1)/r_flare) * !radeg
  if (xy_flare_stix(0) ge 0) AND (xy_flare_stix(1) le 0) then o_flare=90-asin(abs(xy_flare_stix(1))/r_flare) * !radeg
  if (xy_flare_stix(0) le 0) AND (xy_flare_stix(1) le 0) then o_flare=-90+asin(xy_flare_stix(1)/r_flare) * !radeg
  if (xy_flare_stix(0) le 0) AND (xy_flare_stix(1) ge 0) then o_flare=-acos(xy_flare_stix(1)/r_flare) * !radeg
  
  ;;;;; Paolo Massa (September 2021): corrected the definition of 'rel_f' and 'rel_r'. Indeed, the grids in this case
  ;;;;; are considered looking towards the Sun. A minus sign is added to 'fff.o' and 'rrr.o' to keep into account the different
  ;;;;; definition of the orientation angle used in Matej's grid table
  
;  ;orientations of grids relative to flare
;  rel_f=abs(fff.o-o_flare)
;  rel_r=abs(rrr.o-o_flare)
  rel_f=abs(-fff.o-o_flare)
  rel_r=abs(-rrr.o-o_flare)


  ;correction only applies to component normal to the grid orientation
  cor_f=sin(rel_f/180.*!pi)
  cor_r=sin(rel_r/180.*!pi)

  ;nominal thickness with glue
  nom_h=0.42
  ;maximal internal grid shadowing when see for grids with orientation of 90 degrees from center to flare line
  max_c=tan(r_flare/3600./180*!pi)*nom_h
  ;the shadow in mm for each of the entries; this value will be subtracted from the nominal slit width (see below)
  shadow_r=cor_r*max_c
  shadow_f=cor_f*max_c

  ;for bridges: correction is largest for grids with orientation parallel to the center-flare line
  b_cor_f=cos(rel_f/180.*!pi)
  b_cor_r=cos(rel_r/180.*!pi)
  ;the shadow to be added to bridge width (see below)
  b_shadow_r=cor_r*max_c
  b_shadow_f=cor_f*max_c

  gtrans32f=fltarr(32)-2
  gtrans32r=fltarr(32)-2
  btrans32f=fltarr(32)+1
  btrans32r=fltarr(32)+1
  o2flare_f=strarr(32)
  o2flare_r=strarr(32)
  o2zero_f=strarr(32)
  o2zero_r=strarr(32)

  ;for the case the flare location is at [0,0], the code above gives NAN, but correction for internal shadowing should be zero
  if xy_flare(0) eq 0 AND xy_flare(1) eq 0 then begin
    shadow_f=fltarr(39)
    shadow_r=fltarr(39)
  endif

  for i=0,31 do begin
    this_list=where(fff.sc eq i+1)
    ;print,i,fff.sc(this_list)
    ;single layer: transmission = slit/pitch
    if (n_elements(this_list) eq 1) AND (this_list(0) ne -1) then begin
      ;gtrans32f(i)=fff.slit(this_list(0))/fff.p(this_list(0))
      gtrans32f(i)=(fff.slit(this_list(0))-shadow_f(this_list(0)))/fff.p(this_list(0))
      ;gtrans32r(i)=rrr.slit(this_list(0))/rrr.p(this_list(0))
      gtrans32r(i)=(rrr.slit(this_list(0))-shadow_r(this_list(0)))/rrr.p(this_list(0))
      if fff.bpitch(this_list(0)) ne 0 then begin
        btrans32f(i)=1.-fff.bwidth(this_list(0))/fff.bpitch(this_list(0))
        btrans32r(i)=1.-rrr.bwidth(this_list(0))/rrr.bpitch(this_list(0))
      endif
    endif
    ;multi layer grids:
    if n_elements(this_list) ge 2 then begin
      ;slats in each layer (covered part)
      this_slat_f_each=fff.p(this_list)-fff.slit(this_list)
      ;sum of all slats gives lengths of total covered part
      this_slat_f_total=total(this_slat_f_each)
      ;transmission is 1 minus covered/pitch
      gtrans32f(i)=1.-this_slat_f_total/average(fff.p(this_list))
      ;slats in each layer (covered part)
      this_slat_r_each=rrr.p(this_list)-rrr.slit(this_list)
      ;sum of all slats gives lengths of total covered part
      this_slat_r_total=total(this_slat_r_each)
      ;transmission is 1 minus covered/pitch
      gtrans32r(i)=1.-this_slat_r_total/average(rrr.p(this_list))
      ;bridge: only one value in the table
      btrans32f(i)=1.-fff.bwidth(this_list(0))/fff.bpitch(this_list(0))
      btrans32r(i)=1.-rrr.bwidth(this_list(0))/rrr.bpitch(this_list(0))
    endif
  endfor
  ;no bridge measurement for 5 front use 0.05, the nominal value (in file it is set to 0.5 to mark the missing value)
  btrans32f(4)=1.-0.05/fff.bpitch(4)
  ;could apply averaged deviation from nominal instead?

  gtrans32=gtrans32f*gtrans32r*btrans32f*btrans32r
  gtrans32_no_b=gtrans32f*gtrans32r

  ;set CFL and BKG to zero for now
  gtrans32(8:9)=0


  if keyword_set(plot) then begin
    ;goupring of detectors from instrument paper Table 2
    ;labels are from 1 to 32, here we have arrays from 0 to 31
    g10=[3,20,22]-1
    g09=[16,14,32]-1
    g08=[21,26,4]-1
    g07=[24,8,28]-1
    g06=[15,27,31]-1
    g05=[6,30,2]-1
    g04=[25,5,23]-1
    g03=[7,29,1]-1
    g02=[12,19,17]-1
    g01=[11,13,18]-1
    g01_10=[g01,g02,g03,g04,g05,g06,g07,g08,g09,g10]
    res32=fltarr(32)
    res32(g10)=178.6
    res32(g09)=124.9
    res32(g08)=87.3
    res32(g07)=61.0
    res32(g06)=42.7
    res32(g05)=29.8
    res32(g04)=20.9
    res32(g03)=14.6
    res32(g02)=10.2
    res32(g01)=7.1
    clearplot
    plot_oi,res32(g01_10),gtrans32(g01_10),psym=1,xtitle='resolution [arcsec]',ytitle='grid transmission',charsize=1.6,symsize=2,xrange=[5,300],xstyle=1
    ;overplot values without internal shadowing corrections
    gtrans00=stix_gtrans32_test([0,0.])
    oplot,res32(g01_10),gtrans00(g01_10),psym=1,color=4
    ;difference
    oplot,res32(g01_10),gtrans00(g01_10)-gtrans32(g01_10),color=5,psym=1

  endif

  return,gtrans32

END