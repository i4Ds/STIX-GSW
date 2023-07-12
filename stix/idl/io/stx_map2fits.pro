;+
; Project     : STIX
;
; Name        : STX_MAP2FITS
;
; Purpose     : Write STIX reconstructed map to FITS file.
;
; Category    : imaging
;
; Syntax      : stx_map2fits,map,file,path_sci_file
;
; Inputs      : MAP = image map structure
;               FILE = filename of the newly created FITS file
;               PATH_SCI_FILE = path to the L1 file used for reconstructing the STIX image
;
; Keywords    : PATH_BKG_FILE = path to the L1 BKG file included for the reconstruction of the STIX image
;               ERR = error string
;               BYTE_SCALE = byte scale data
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
;                  
;                - 24.05.2023: A. F. Battaglia
;                  Extensive update of the procedure. Now aspect data are used and the header
;                  is more conformed with the FITS standard
; -

   pro stx_map2fits,map,file,path_sci_file,path_bkg_file=path_bkg_file,$
    err=err,byte_scale=byte_scale,verbose=verbose

   err=''
   verbose=keyword_set(verbose)

  ;; Check if the L1 file is given
  if not keyword_set(path_sci_file) then begin
    print, ''
    print, ' >>>>>>>>>> path_sci_file has to be defined!! <<<<<<<<<<'
    print, ''
    message, 'Please, define path_sci_file (path to the science file that has been used for imaging)'
  endif
    

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

;-- FITS parameters CRPIX, CRVAL, etc.

    crpix1=comp_fits_crpix(xcen,cdelt1,naxis1,0)
    crpix2=comp_fits_crpix(ycen,cdelt2,naxis2,0)
        
    ;; Extract the time and energy ranges from the map
    time_range = [anytim(map[i].time)-map[i].dur/2.,anytim(map[i].time)+map[i].dur/2.]
    energy_range = map[i].energy_range
    
    ;; Algorithm used
    alg = map[i].id
    algo_used = alg.remove(-2,-1)
    
    ;; Extract pointing information
    aux_data = map[i].aux_data
    stx_x = aux_data.stx_pointing[0]
    stx_y = aux_data.stx_pointing[1]
    rsun_arc = map[i].rsun
    roll_angle = map[i].roll_angle
    l0_ang = map[i].l0
    b0_ang = map[i].b0
    
    ;; Component of the PC matrix
    roll_angle_rad = roll_angle * !dpi / 180.
    pc1_1 = cos(roll_angle_rad) 
    pc1_2 = -sin(roll_angle_rad) 
    pc2_1 = sin(roll_angle_rad) 
    pc2_2 = cos(roll_angle_rad) 
    
    ;; Get the current time for the creation date of the FITS file
    get_date, cur_date, /time
    fits_creation_datetime = anytim(cur_date,/ccsds)
    
    ;; Get the header of the L1 FITS file used for creating the STIX map
    this_header = headfits(path_sci_file)
    
    ;; Extract the filename of the L1 data used for the visibilities
    break_file,path_sci_file,disk_log,dir_l1,fn_sci_file,ext_sci_file
    if keyword_set(path_bkg_file) then break_file,path_bkg_file,disk_log,dir_bkg,fn_bkg_file,ext_bkg_file
    
    ;;; Get the proper time format
    ; Begin time of the interval of integration
    time_beg_structure = anytim(time_range[0],/utc_ext)
    time_end_structure = anytim(time_range[1],/utc_ext)
    time_avg_structure = anytim(mean(time_range),/utc_ext)
    this_date_obs = anytim(time_range[0], /ccsds)
    this_date_obs_end = anytim(time_range[1], /ccsds)
    this_date_obs_avg = anytim(mean(time_range), /ccsds)
    
    ; Let us add parameters to the header structure
    fxaddpar, header, 'TELESCOP', sxpar(this_header,'TELESCOP'), 'Telescope name'
    fxaddpar, header, 'INSTRUME', sxpar(this_header,'INSTRUME'), 'Instrument name'
    fxaddpar, header, 'OBSRVTRY', sxpar(this_header,'OBSRVTRY'), 'Satellite name'
    fxaddpar, header, 'FLNM_SCI', fn_sci_file+ext_sci_file, 'Filename science L1 file'
    if keyword_set(path_bkg_file) then fxaddpar, header, 'FLNM_BKG', fn_bkg_file+ext_bkg_file, 'Filename background L1 file'
    fxaddpar, header, 'LEVEL   ', sxpar(this_header,'LEVEL   '), 'Processing level of the data used for the map'
    fxaddpar, header, 'TIMESYS ', sxpar(this_header,'TIMESYS '), 'System used for time keywords'
    fxaddpar, header, 'DATE_CRE', fits_creation_datetime, 'FITS file creation time in UTC'
    ;fxaddpar, header, 'ORIGIN  ', sxpar(this_header,'ORIGIN  '), 'Location where file has been generated'
    fxaddpar, header, 'ORIGIN  ', 'User', 'Location where file has been generated'
    fxaddpar, header, 'CREATOR ', 'stx_map2fits, IDL', 'FITS creation software'
    fxaddpar, header, 'OBS_TYPE', 'STIX-map'
    fxaddpar, header, 'DATE-OBS', this_date_obs, 'Start time of the map interval - SolO UT'
    fxaddpar, header, 'DATE-BEG', this_date_obs, 'Start time of the map interval - SolO UT'
    fxaddpar, header, 'DATE-AVG', this_date_obs_avg, 'Average time of the map interval - SolO UT'
    fxaddpar, header, 'DATE-END', this_date_obs_end, 'End time of the map interval - SolO UT'
    fxaddpar, header, 'MJDREF  ', sxpar(this_header,'MJDREF  ')
    fxaddpar, header, 'DATEREF ', sxpar(this_header,'DATEREF ')
    fxaddpar, header, 'ALG_USED', algo_used, 'Algo used for imaging reconstr'
    fxaddpar, header, 'ENERGY_L', string(energy_range[0]), '[keV] Low energy bound of the map'
    fxaddpar, header, 'ENERGY_H', string(energy_range[1]), '[keV] High energy bound of the map'
    fxaddpar, header, 'STX_X   ', stx_x, '[arcsec] STIX pointing estimate'
    fxaddpar, header, 'STX_Y   ', stx_y, '[arcsec] STIX pointing estimate'
    fxaddpar, header, 'TARGET  ', 'Sun'
    fxaddpar, header, 'SPICE_MK', sxpar(this_header,'SPICE_MK'), 'SPICE meta kernel file'
    fxaddpar, header, 'RSUN_REF', 695700000.0, '[m] Assumed physical solar radius'
    fxaddpar, header, 'RSUN_OBS', rsun_arc, '[arcsec] Apparent photospheric solar radius'
    fxaddpar, header, 'RSUN_ARC', rsun_arc, '[arcsec] Apparent photospheric solar radius'
    fxaddpar, header, 'HGLT_OBS', b0_ang, '[deg] s/c heliographic latitude (B0 angle)'
    fxaddpar, header, 'HGLN_OBS', sxpar(this_header,'HGLN_OBS'), '[deg] s/c heliographic longitude'
    fxaddpar, header, 'CRLT_OBS', b0_ang, '[deg] s/c Carrington latitude (B0 angle)'
    fxaddpar, header, 'CRLN_OBS', l0_ang, '[deg] s/c Carrington longitude (L0 angle)'
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
    
    ; FITS parameters CRPIX, CRVAL
    fxaddpar, header, 'CTYPE1', 'HPLN-TAN','Solar X (cartesian west) axis'
    fxaddpar, header, 'CTYPE2', 'HPLT-TAN','Solar Y (cartesian north) axis'
    fxaddpar, header, 'CRPIX1', crpix1, 'Reference pixel along X dimension'
    fxaddpar, header, 'CRPIX2', crpix2, 'Reference pixel along Y dimension'
    fxaddpar, header, 'CRVAL1',0, 'Reference position along X dimension'
    fxaddpar, header, 'CRVAL2',0, 'Reference position along Y dimension'
    fxaddpar, header, 'CDELT1',cdelt1,'Increments along X dimension'
    fxaddpar, header, 'CDELT2',cdelt2,'Increments along Y dimension'
    fxaddpar,header,'PC1_1',pc1_1,'WCS coordinate transformation matrix'
    fxaddpar,header,'PC1_2',pc1_2,'WCS coordinate transformation matrix'
    fxaddpar,header,'PC2_1',pc2_1,'WCS coordinate transformation matrix'
    fxaddpar,header,'PC2_2',pc2_2,'WCS coordinate transformation matrix'
    fxaddpar,header,'CROTA1',roll_angle,'[deg] Roll angle'
    fxaddpar,header,'CROTA2',roll_angle,'[deg] Roll angle'
    fxaddpar,header,'CUNIT1','arcsec  ','units along axis 1'
    fxaddpar,header,'CUNIT2','arcsec  ','units along axis 2'
    fxaddpar,header,'CROTACN1',map[i].roll_center[0],'[arcsec] Rotation x center'
    fxaddpar,header,'CROTACN1',map[i].roll_center[1],'[arcsec] Rotation y center'

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
