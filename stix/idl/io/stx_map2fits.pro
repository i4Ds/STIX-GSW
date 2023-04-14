;+
; Project     : STIX
;
; Name        : STX_MAP2FITS
;
; Purpose     : Write STIX image reconstructed map to FITS file. The header of
;               newly created FITS file depends on the reconstruction algorithm
;               used.
;
; Category    : imaging
;
; Syntax      : stx_map2fits,map,file,path_sci_file
;
; Inputs      : MAP = image map structure
;               FILE = FITS file name
;               PATH_SCI_FILE = path to the L1 file used for reconstructing the STIX image
;
; Keywords    : PATH_BKG_FILE = path to the L1 BKG file included for the reconstruction of the STIX image
;               XY_SHIFT = applied shift to the location of the map. Provide the aspect if applied
;               ERR = error string
;               BYTE_SCALE = byte scale data
;               ALL_CLEAN = store all maps of the clean map structure 
;                           (by default only the clean map is stored, i.e., clean_map[0])
;
; Comments    : Based on map2fits in sswidl, but adapted for STIX images
; History     : 05-04-2022, Hualin Xiao (hualin.xiao@fhnw.ch)
;                - copied map2fits from ssw and add more keywords to the 
;                  header to make generated fits files be compatible with sunpy.map
;                
;                - 17.05.2022: A. F. Battaglia (andrea-battaglia@fhnw.ch)
;                  It now includes most of the keywords already present in the L1 science file.
;                  Now the user MUST specify path_sci_file
;
;                - 04.07.2022: A. F. Battaglia (andrea-battaglia@fhnw.ch)
;                  Keyword ALL_CLEAN added. By default, only the clean_map[0] is stored
;
;                - 04.11.2022: A. F. Battaglia
;                  DATE-OBS added (before only DATE_OBS). For better compatibility with
;                  other languages.
;                  
;                - 03.04.2023: A. F. Battaglia
;                  RSUN_REF added. The same value as in the EUI FITS files has been added
; -

   pro stx_map2fits,in_map,file,path_sci_file,path_bkg_file=path_bkg_file,$
    xy_shift=xy_shift, err=err,byte_scale=byte_scale,verbose=verbose,all_clean=all_clean

   err=''
   verbose=keyword_set(verbose)

  ; ******************** ADAPTED FOR STIX ************************

  ; Check if the L1 file is given
  if not keyword_set(path_sci_file) then begin
    print, ''
    print, ' >>>>>>>>>> path_sci_file has to be defined!! <<<<<<<<<<'
    print, ''
    message, 'Please, define path_sci_file (path to the science file used for imaging)'
  endif
    
  ; Check if the algorithm used is CLEAN.
  ; If this is the case, then store only the CLEAN map and discard all other maps
  this_id = in_map[0].id
  if this_id.Contains('CLEAN') eq 1 and not keyword_set(all_clean) then begin
    map = in_map[0]
  endif else begin
    map = in_map
  endelse

  ; *************************************************************

   if ~valid_map(map) || is_blank(file) then begin
    pr_syntax,'map2fits,map,file'
    return
   endif
   np=n_elements(map)

;-- form output file name

   cd,curr=cdir
   break_file,file,dsk,dir,dfile,dext
   if trim(dsk+dir) eq '' then fdir=cdir else fdir=dsk+dir
   if ~file_test(fdir,/write) then begin
    err='No write access to - '+fdir
    message,err,/info
    return
   endif
   if trim(dext) eq '' then fext='.fits' else fext=dext
   filename=concat_dir(fdir,dfile)+fext
   filename=filename.Replace("'","")
   
   if verbose then message,'Writing map to - '+filename,/info
   use_rtime=tag_exist(map,'rtime')
   in_tags=tag_names(map)
   def_map,rmap
   def_fits=['SIMPLE','BITPIX','NAXIS','NAXIS1','NAXIS2','DATE','FILENAME','END',$
             'COMMENT','HISTORY']
   ignore=[tag_names(rmap),def_fits]
   delvarx,header
   for i=0,np-1 do begin

;-- unpack data

    unpack_map,map[i],data,xp,yp,dx=cdelt1,dy=cdelt2,xc=xcen,yc=ycen,$
      nx=naxis1,ny=naxis2

;-- scale data?

    if keyword_set(byte_scale) then bscale,data,top=255

;-- add header for the output array.

    fxhmake,header,data,/date

;-- add FITS parameters CRPIX, CRVAL, etc.

    crpix1=comp_fits_crpix(xcen,cdelt1,naxis1,0)
    crpix2=comp_fits_crpix(ycen,cdelt2,naxis2,0)

    fxaddpar, header, 'ctype1', 'solar_x','Solar X (cartesian west) axis'
    fxaddpar, header, 'ctype2', 'solar_y','Solar Y (cartesian north) axis'

;    fxaddpar, header, 'cunit1', 'arcsecs','Arcseconds from center of Sun'
;    fxaddpar, header, 'cunit2', 'arcsecs','Arcseconds from center of Sun'

    fxaddpar, header, 'crpix1', crpix1, 'Reference pixel along X dimension'
    fxaddpar, header, 'crpix2', crpix2, 'Reference pixel along Y dimension'

    fxaddpar, header, 'crval1',0, 'Reference position along X dimension'
    fxaddpar, header, 'crval2',0, 'Reference position along Y dimension'

    fxaddpar, header, 'cdelt1',cdelt1,'Increments along X dimension'
    fxaddpar, header, 'cdelt2',cdelt2,'Increments along Y dimension'

    if use_rtime then obs_time=map[i].rtime else obs_time=map[i].time

    fxaddpar,header,'date_obs',obs_time,'Observation date'
    fxaddpar,header,'date-obs',obs_time,'Observation date'
    if tag_exist(map,'dur') then fxaddpar,header,'exptime',map[i].dur,'Exposure duration'
    fxaddpar,header,'origin',map[i].id,'Data description'
    
    
    ; ******************** ADAPTED FOR STIX ************************
    
    ; Extract the time and energy ranges from the map
    time_range = [anytim(map.time)-map.dur/2.,anytim(map.time)+map.dur/2.]
    ;energy_axis = map.energy_range
    
    ; Algorithm used
    ;algo_used = map.image_alg
    
    ; If xy_shift is not provided, then put the average shift values in the header
    if not keyword_set(xy_shift) then xy_shift = [26.1, 58.2]
    
    ; Get the header of the L1 FITS file used for creating the STIX map
    this_header = headfits(path_sci_file)
    
    ; Extract the filename of the L1 data used for the visibilities
    break_file,path_sci_file,disk_log,dir_l1,fn_sci_file,ext_sci_file
    if keyword_set(path_bkg_file) then break_file,path_bkg_file,disk_log,dir_bkg,fn_bkg_file,ext_bkg_file
    
    ; Get the proper time format
    time_structure = anytim(time_range[0],/utc_ext)
    this_date_str = num2str(time_structure.year,format='(I10.4)')+'-'$
      +num2str(time_structure.month,format='(I10.2)')+'-'$
      +num2str(time_structure.day,format='(I10.2)')
    this_time_str = num2str(time_structure.hour,format='(I10.2)')+':'$
      +num2str(time_structure.minute,format='(I10.2)')+':'$
      +num2str(time_structure.second,format='(I10.2)')+'.'$
      +num2str(time_structure.millisecond,format='(I10.3)')
    this_date_obs = this_date_str + ' ' + this_time_str
    
    ; Let us add parameters to the header structure
    fxaddpar, header, 'TELESCOP', sxpar(this_header,'TELESCOP'), 'Telescope name'
    fxaddpar, header, 'INSTRUME', sxpar(this_header,'INSTRUME'), 'Instrument name'
    fxaddpar, header, 'OBSRVTRY', sxpar(this_header,'OBSRVTRY'), 'Satellite name'
    fxaddpar, header, 'FLNM_SCI', fn_sci_file+ext_sci_file, 'Filename science L1 file'
    if keyword_set(path_bkg_file) then fxaddpar, header, 'FLNM_BKG', fn_bkg_file+ext_bkg_file, 'Filename background L1 file'
    fxaddpar, header, 'LEVEL   ', sxpar(this_header,'LEVEL   '), 'Processing level of the data used for the map'
    fxaddpar, header, 'TIMESYS ', sxpar(this_header,'TIMESYS '), 'System used for time keywords'
    fxaddpar, header, 'DATE_CRE', sxpar(this_header,'DATE    '), 'FITS file creation time in UTC'
    fxaddpar, header, 'ORIGIN  ', sxpar(this_header,'ORIGIN  '), 'Location where file has been generated'
    fxaddpar, header, 'CREATOR ', 'stx_map2fits, IDL', 'FITS creation software'
    fxaddpar, header, 'OBS_TYPE', 'STIX-map'
    fxaddpar, header, 'DATE-OBS', this_date_obs, 'Start time of the map interval - SolO UT'
    ;fxaddpar, header, 'DATE-OBS', anytim(time_range[0],/ccsds), 'Start time of the map interval - SolO UT'
    fxaddpar, header, 'DATE_OBS', anytim(time_range[0],/ccsds), 'Start time of the map interval - SolO UT'
    fxaddpar, header, 'DATE_BEG', anytim(time_range[0],/ccsds), 'Start time of the map interval - SolO UT'
    fxaddpar, header, 'DATE_AVG', anytim((anytim(time_range[0])+anytim(time_range[1]))/2,/ccsds), 'Average time of the map interval - SolO UT'
    fxaddpar, header, 'DATE_END', anytim(time_range[1],/ccsds), 'End time of the map interval - SolO UT'
    fxaddpar, header, 'MJDREF  ', sxpar(this_header,'MJDREF  ')
    fxaddpar, header, 'DATEREF ', sxpar(this_header,'DATEREF ')
   ; fxaddpar, header, 'ENERGY_L', string(energy_axis[0]), '[keV] Low energy range of the map interval'
   ; fxaddpar, header, 'ENERGY_H', string(energy_axis[1]), '[keV] High energy range of the map interval'
    ;fxaddpar, header, 'MAP_CENX', string(this_mapcenter[0,0]), '[arcsec] Map center X - STIX RF'
    ;fxaddpar, header, 'MAP_CENY', string(this_mapcenter[1,0]), '[arcsec] Map center Y - STIX RF'
    fxaddpar, header, 'X_SHIFT ', string(xy_shift[0]), '[arcsec] Applied shift to map X - SolO RF'
    fxaddpar, header, 'Y_SHIFT ', string(xy_shift[1]), '[arcsec] Applied shift to map Y - SolO RF'
    fxaddpar, header, 'TARGET  ', 'Sun'
    fxaddpar, header, 'SPICE_MK', sxpar(this_header,'SPICE_MK'), 'SPICE meta kernel file'
    fxaddpar, header, 'RSUN_REF', 695700000.0, '[m] Assumed physical solar radius'
    fxaddpar, header, 'RSUN_OBS', sxpar(this_header,'RSUN_ARC'), '[arcsec] Apparent photospheric solar radius'
    fxaddpar, header, 'RSUN_ARC', sxpar(this_header,'RSUN_ARC'), '[arcsec] Apparent photospheric solar radius'
    fxaddpar, header, 'HGLT_OBS', sxpar(this_header,'HGLT_OBS'), '[deg] s/c heliographic latitude (B0 angle)'
    fxaddpar, header, 'HGLN_OBS', sxpar(this_header,'HGLN_OBS'), '[deg] s/c heliographic longitude'
    fxaddpar, header, 'CRLT_OBS', sxpar(this_header,'CRLT_OBS'), '[deg] s/c Carrington latitude (B0 angle)'
    fxaddpar, header, 'CRLN_OBS', sxpar(this_header,'CRLN_OBS'), '[deg] s/c Carrington longitude (L0 angle)'
    fxaddpar, header, 'DSUN_OBS', sxpar(this_header,'DSUN_OBS'), '[m] s/c distance from Sun'
    fxaddpar, header, 'HEEX_OBS', sxpar(this_header,'HEEX_OBS'), '[m] s/c Heliocentric Earth Ecliptic X'
    fxaddpar, header, 'HEEY_OBS', sxpar(this_header,'HEEY_OBS'), '[m] s/c Heliocentric Earth Ecliptic Y'
    fxaddpar, header, 'HEEZ_OBS', sxpar(this_header,'HEEZ_OBS'), '[m] s/c Heliocentric Earth Ecliptic Z'
    fxaddpar, header, 'HCIX_OBS', sxpar(this_header,'HCIX_OBS'), '[m] s/c Heliocentric Inertial X'
    fxaddpar, header, 'HCIY_OBS', sxpar(this_header,'HCIY_OBS'), '[m] s/c Heliocentric Inertial Y'
    fxaddpar, header, 'HCIZ_OBS', sxpar(this_header,'HCIZ_OBS'), '[m] s/c Heliocentric Inertial Z'
    fxaddpar, header, 'HCIX_VOB', sxpar(this_header,'HCIX_VOB'), '[m/s] s/c Heliocentric Inertial X Velocity'
    fxaddpar, header, 'HCIY_VOB', sxpar(this_header,'HCIY_VOB'), '[m/s] s/c Heliocentric Inertial Y Velocity'
    fxaddpar, header, 'HCIZ_VOB', sxpar(this_header,'HCIZ_VOB'), '[m/s] s/c Heliocentric Inertial Z Velocity'
    fxaddpar, header, 'HAEX_OBS', sxpar(this_header,'HAEX_OBS'), '[m] s/c Heliocentric Aries Ecliptic X'
    fxaddpar, header, 'HAEZ_OBS', sxpar(this_header,'HAEY_OBS'), '[m] s/c Heliocentric Aries Ecliptic Y'
    fxaddpar, header, 'HAEZ_OBS', sxpar(this_header,'HAEY_OBS'), '[m] s/c Heliocentric Aries Ecliptic Z'
    fxaddpar, header, 'HEQX_OBS', sxpar(this_header,'HEQX_OBS'), '[m] s/c Heliocentric Earth Equatorial X'
    fxaddpar, header, 'HEQY_OBS', sxpar(this_header,'HEQY_OBS'), '[m] s/c Heliocentric Earth Equatorial Y'
    fxaddpar, header, 'HEQZ_OBS', sxpar(this_header,'HEQZ_OBS'), '[m] s/c Heliocentric Earth Equatorial Z'
    fxaddpar, header, 'GSEX_OBS', sxpar(this_header,'GSEX_OBS'), '[m] s/c Geocentric Solar Ecliptic X'
    fxaddpar, header, 'GSEY_OBS', sxpar(this_header,'GSEY_OBS'), '[m] s/c Geocentric Solar Ecliptic Y'
    fxaddpar, header, 'GSEZ_OBS', sxpar(this_header,'GSEZ_OBS'), '[m] s/c Geocentric Solar Ecliptic Z'
    fxaddpar, header, 'OBS_VR  ', sxpar(this_header,'OBS_VR  '), '[m/s] Radial velocity s/c'
    fxaddpar, header, 'EAR_TDEL', sxpar(this_header,'EAR_TDEL'), '[s] Time(Sun to Earth) - Time(Sun to S/C)'
    fxaddpar, header, 'SUN_TIME', sxpar(this_header,'SUN_TIME'), '[s] Time(Sun to s/c)'
    earth_time = anytim(time_range[0]) + anytim(sxpar(this_header,'EAR_TDEL'))
    fxaddpar, header, 'DATE_EAR', anytim(earth_time,/ccsds), 'Start time vis interval, corrected to Earth'
    sun_time = anytim(time_range[0]) - anytim(sxpar(this_header,'SUN_TIME'))
    fxaddpar, header, 'DATE_SUN', anytim(sun_time,/ccsds), 'Start time vis interval, corrected to Sun'
    
    ; Entries that depend from the map
    fxaddpar,header,'CROTA1',map[i].roll_angle,'[deg] Roll angle'
    fxaddpar,header,'CROTA2',map[i].roll_angle,'[deg] Roll angle'
    fxaddpar,header,'CUNIT1','arcsec  ','units along axis 1'
    fxaddpar,header,'CUNIT2','arcsec  ','units along axis 2'
    fxaddpar,header,'CROTACN1',map[i].roll_center[0],'[arcsec] Rotation x center'
    fxaddpar,header,'CROTACN1',map[i].roll_center[1],'[arcsec] Rotation y center'
    if tag_exist(map[i],'L0') then fxaddpar,header,'L0',map[i].l0,'L0 (degrees)'
    if tag_exist(map[i],'B0') then fxaddpar,header,'B0',map[i].b0,'B0 (degrees)'
    if tag_exist(map[i],'RSUN') then fxaddpar,header,'RSUN',map[i].rsun,'Solar radius (arcsecs)'
    ;if tag_exist(map[i],'RSUN') then fxaddpar,header,'RSUN_OBS',map[i].rsun,'Solar radius (arcsecs)'
    ;if tag_exist(map[i],'DSUN') then fxaddpar,header,'DSUN_OBS',map[i].dsun,'S/C distance to Sun (meters)'
    ;if tag_exist(map[i],'L0') then fxaddpar,header,'HGLN_OBS',map[i].l0,'S/C longitude in HeliographicStonyhurst coord. (degrees)'
    ;f tag_exist(map[i],'B0') then fxaddpar,header,'HGLT_OBS',map[i].b0,'S/C latitude in HeliographicStonyhurst coord. (degrees)'
    
    ; **************************************************************


;-- add in user-specified properties

    for k=0,n_elements(in_tags)-1 do begin
     chk=where(in_tags[k] eq ignore,count)
     if count gt 0 then continue
     if ~is_scalar(map[i].(k)) then begin
;      mprint,'Skipping non-scalar user-defined property - '+in_tags[k]
      continue
    endif

     fxaddpar,header,in_tags[k],map[i].(k),''
    endfor

    fxaddpar, header, 'filename', file_basename(filename),'FILENAME'

;-- add optional comments or history
  
    if tag_exist(map[i],'comment') then begin
     comments=map[i].comment
     for k=0,n_elements(comments)-1 do if is_string(comments[k]) then fxaddpar,header,'COMMENT',comments[k]
    endif

    if tag_exist(map[i],'history') then begin
     histories=map[i].history
     for k=0,n_elements(histories)-1 do if is_string(histories[k]) then fxaddpar,header,'HISTORY',histories[k]
    endif

;-- write out the file

    fxwrite, filename, header,data,append=(i gt 0)
   endfor

   return & end
