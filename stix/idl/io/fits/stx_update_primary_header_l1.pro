;+
; :project:
;       STIX
;
; :name:
;       stx_update_primary_header_ll01
;
; :purpose:
;       Update a fits header to contain required l1 tags
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
;       version : in type="str"
;           Version of the file must match filename
;           
;       obs_mode : in type="str"
;           Instrument observation mode
;           
;       date-obs : in type="str"
;           Date of observation in UTC
;      
;       date-beg : in type="str"
;           Start of observation in UTC
;           
;       date-avg : in type="str"
;           Average of observation in UTC
;
;       date-end : in type="str"
;           End of observation in UTC
;
;       obs_type : in type="str"
;           Encoded version of obs_mode
;           
;       soop_type : in type="str"
;           Soop Type associate with the observation
;           
;       obs-id : in type="str"
;           Observation id
;
;       obs_target : in type="str"
;           Target "Sun"
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
function stx_update_primary_header_l1, header=header, filename=filename, create_date=create_date, $
    obt_beg=obt_beg, obt_end=obt_end, version=version, obs_mode=obs_mode, date_obs=date_obs, $
    date_beg=date_beg, date_avg=date_avg, date_end=date_end, obs_type=obs_type, $
    soop_type=soop_type, obs_id=obs_id, obs_target=obs_target

    ; Fixed for L01
    timesys = 'UTC'
    level = 'L1'
    creator = 'STIX-SWF'
    file_origin = 'STIX Team, FHNW'
    vers_sw = '1' ;git taged realease maybe

    header = stx_update_primary_fits_header_common(header=header, filename=filename, $
        create_date=create_date, obt_beg=obt_beg, obt_end=obt_end, timesys=timesys, level=level, $
        file_origin=file_origin, creator=creator, version=version, obs_mode=obs_mode, $
        vers_sw=vers_sw)

    ; Add additional L1 headers
    sxaddpar, header, 'DATE-OBS', date_obs
    sxaddpar, header, 'DATE-BEG', date_beg
    sxaddpar, header, 'DATE-AVG', date_avg
    sxaddpar, header, 'DATE-END', date_end
    sxaddpar, header, 'OBS_TYPE', obs_type
    sxaddpar, header, 'SOOP_TYPE', soop_type
    sxaddpar, header, 'OBS_ID', obs_id
    sxaddpar, header, 'TARGET', obs_target

    return, header
end