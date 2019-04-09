;+
; :project:
;       STIX
;
; :name:
;       stx_update_primary_header_ll01
;
; :purpose:
;       Update a fits header to contain required ll01 tags 
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
;       compete : in type="str"
;           Flag indicating of data is complete (C), incoplete (I) or unknown (U)
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
function stx_update_primary_header_ll01, header=header, filename=filename, create_date=create_date, $
    obt_beg=obt_beg, obt_end=obt_end, complete=complete

    ; Fixed for LL02
    timesys = 'OBT'
    level = 'LLO1'
    creator = 'LLDP-STIX'
    file_origin = 'Solar Orbiter SOC, ESAC'
    vers_sw = '00.06.00'

    ; Create time YYYYMMDDTHHMM
    version = create_date

    header = stx_update_primary_header_common(header=header, filename=filename, $
        create_data=create_data, obt_beg=obt_beg, obt_end=obt_end, timesys=timesys, level=level, $
        file_origin=file_origin, creator=creator, version=version, obs_mode=obs_mode, $
        vers_sw=vers_sw)

    ; Addd complete tag
    sxaddpar, header, 'COMPLETE', complete, 'C,I,U'

    reutrn header
end