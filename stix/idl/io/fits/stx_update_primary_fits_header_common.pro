;+
; :project:
;       STIX
;
; :name:
;       stx_update_primary_fits_header_common
;
; :purpose:
;       Update a fits head to contain common tags
;
; :categories:
;       telemetry, fits, io
;
; :keyword:
;       header : in, type="str"
;           Optional the header to add to
;
;       filename : in, type="str"
;           File name the fits file will be written to
;           
;       create_date : in type="str
;           Creation date and time of fits file
;
;       obt_beg : in, type="double"
;           Start OBT time of data in TM
;
;       obt_end : in, type="double"
;           Start OBT time of data in TM
;           
;       timesys : in, type="str"
;           Time system for times (UTC or OBT)
;           
;       level : in type="str"
;           Level of data e.g. LL01, L0, L1, L2
;           
;       creator : in type="str"
;           Software creating the file e.g. LLDP-STIX or STIX-SFW
;           
;       version : in type="str"
;           Version of the file
;       
;       obs_mode : in type="str"
;           Obs mode of the instruemnt
;           
;       vers_sw : un type="str"
;           Software version that created file
;
; :returns:
;       Fits header data as string array
;
; :examples:
;
; :history:
;       09-April-2019 – SAM (TCD) init
;
;-
function stx_update_primary_fits_header_common, header=header, filename=filename, $
    create_date=create_date, obt_beg=obt_beg, obt_end=obt_end, timesys=timesys, $
    level=level, file_origin=file_origin, creator=creator, version=version, obs_mode=obs_mode, $
    vers_sw=vers_sw
    
    ; Fixed for STIX    
    sxaddpar, header, 'TELESCOP', 'SOLO/STIX'
    sxaddpar, header, 'INSTRUME', 'STIX'
    sxaddpar, header, 'OBSRVTRY', 'Solar Orbiter' 
    
    ; Variable
    sxaddpar, header, 'FILENAME', filename
    sxaddpar, header, 'DATE', create_date
    sxaddpar, header, 'OBT_BEG', obt_beg    
    sxaddpar, header, 'OBT_END', obt_end     
    sxaddpar, header, 'TIMESYS', timesys
    sxaddpar, header, 'LEVEL', level 
    sxaddpar, header, 'ORIGIN', file_origin
    sxaddpar, header, 'CREATOR', creator
    sxaddpar, header, 'VERSION', version 
    sxaddpar, header, 'OBS_MODE', obs_mode
    sxaddpar, header, 'VERS_SW', vers_sw
 
    return, header
end