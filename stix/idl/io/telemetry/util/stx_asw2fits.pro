;+
; :description:
;    Create fits files out os stx_asw structures
;    
; :history:
;    24-Nov-2016 - Simon MArcin (FHNW), initial release
;-



function lightcurve2fits, input, filename, obs_mode=obs_mode, $
  complete_flag=complete_flag, _extra=_extra

  
  ;get size of x-axis
  nbr_time_bins=n_elements(input.triggers)
  nbr_energy_bins=n_elements(input.energy_axis.LOW_FSW_IDX)
  
  ; ----- extension data 1
  ex1_data_entry = {$
    counts: fltarr(nbr_energy_bins), $
    channel: indgen(nbr_energy_bins), $
    relative_time: 0.0 $
    }
  
  ex1_data = replicate(ex1_data_entry,nbr_time_bins)
  
  ; fill data structure
  integration_time = float(input.time_axis.duration[0])
  offset = integration_time / 2.0
  for i=0L,nbr_time_bins-1 do begin
    ex1_data[i].counts = float(input.counts[*,i])
    ex1_data[i].relative_time = i*integration_time+offset
  endfor
    
  ; ----- extension data 2
  ex2_data_entry = {$
    channel: 0, $
    e_min: 0.0, $
    e_max: 0.0 $
  }

  ex2_data = replicate(ex2_data_entry,nbr_energy_bins)

  ; fill data structure
  for i=0,nbr_energy_bins-1 do begin
    ex2_data[i].channel = i
    ex2_data[i].e_min = input.energy_axis.low[i]
    ex2_data[i].e_max = input.energy_axis.high[i]
  endfor
 
  ; No primary array
  mwrfits,!NULL,filename, /create
  ; write data in order to extract a header
  mwrfits,ex1_data,filename
  mwrfits,ex2_data,filename
  header = headfits(filename)
  ex1_header = headfits(filename, EXTEN=1)
  ex2_header = headfits(filename, EXTEN=2)
  
  ; complete header ex1 & ex2
  sxaddpar, ex1_header, 'TUNIT1', 'counts/s/cm2', 'Unit for COUNTS'
  sxaddpar, ex1_header, 'TUNIT2', '', 'Unit for CHANNEL'
  sxaddpar, ex1_header, 'TUNIT3', 's', 'Unit for RELATIVE_TIME'
  sxaddpar, ex2_header, 'ENEBAND', 'Extension name'
  sxaddpar, ex2_header, 'TUNIT1', ''
  sxaddpar, ex2_header, 'TUNIT2', 'keV'
  sxaddpar, ex2_header, 'TUNIT3', ' keV'
  create_header, header=header, filename=filename, integration_time=integration_time,$
    obt_start=obt_start, obt_end=obt_end
  
  mwrfits,!NULL,filename,header,/create, status=stat0
  mwrfits,ex1_data,filename,ex1_header, status=stat1
  mwrfits,ex2_data,filename,ex2_header, status=stat2
  
  if stat0+stat1+stat2 ne 0 then return, 0
  return, 1
end



function flareflag2fits, input, filename, obs_mode=obs_mode, $
  complete_flag=complete_flag, _extra=_extra


  ;get size of x-axis
  nbr_time_bins=n_elements(input.flare_flag)

  ; ----- extension data 1
  ex1_data_entry = {$
    Y_POS: 0.0, $
    Z_POS: 0.0, $
    POS_VALID: 0b, $
    FLARE_FLAG: 0b, $
    relative_time: 0.0 $
  }

  ex1_data = replicate(ex1_data_entry,nbr_time_bins)

  ; fill data structure
  integration_time = float(input.time_axis.duration[0])
  offset = integration_time / 2.0
  for i=0L,nbr_time_bins-1 do begin
    ex1_data[i].Y_POS = float(input.y_pos[i])
    ex1_data[i].Z_POS = float(input.x_pos[i])
    ex1_data[i].FLARE_FLAG = input.flare_flag[i] 
    ;ex1_data[i].POS_VALID = input.pos_valid[i] 
    ex1_data[i].relative_time = i*integration_time+offset
  endfor


  ; No primary array
  mwrfits,!NULL,filename, /create
  ; write data in order to extract a header
  mwrfits,ex1_data,filename
  header = headfits(filename)
  ex1_header = headfits(filename, EXTEN=1)

  ; complete header ex1 & ex2
  sxaddpar, ex1_header, 'TUNIT1', 'arcmin', 'Unit for Y_POS'
  sxaddpar, ex1_header, 'TUNIT2', 'arcmin', 'Unit for Z_POS'
  sxaddpar, ex1_header, 'TUNIT3', '', 'Unit for POS_VALID'
  sxaddpar, ex1_header, 'TUNIT4', '', 'Unit for FLARE_FLAG'
  sxaddpar, ex1_header, 'TUNIT5', 's', 'Unit for RELATIVE_TIME'
  create_header, header=header, filename=filename, integration_time=integration_time, $
    obt_start=obt_start, obt_end=obt_end
  

  mwrfits,!NULL,filename,header,/create, status=stat0
  mwrfits,ex1_data,filename,ex1_header, status=stat1
  mwrfits,ex2_data,filename,ex2_header, status=stat2

  if stat0+stat1+stat2 ne 0 then return, 0
  return, 1
end


pro create_header, header=header, filename=filename, version=version,$
  integration_time=integration_time, obs_mode=obs_mode, $
  complete_flag=complete_flag, obt_beg=obt_beg, obt_end=obt_end, $
  _extra=_extra
  
  default, version, 238
  default, obs_mode, 'NOMINAL'
  default, complete_flag, 'C'
  
  default, obt_beg, 0
  default, obt_end, 0
  
  ;ToDo: OBT_Time Stuff
  
  name = FILE_BASENAME(filename)
  ; 'solo_LL01_stix-flareinfo_0000086399.1234.fits'
  timestr = string(systime(/UTC))
  history = ' createfits ' + trim(string(version))

  ;ToDo: OBT time and date
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'FILENAME',name,'FITS filename'
  sxaddpar, header, 'DATE',timestr,'FITS file creation date in UTC'
  sxaddpar, header, 'OBT-BEG',trim(string(obt_beg)),'Start of acquisition time in OBT'
  sxaddpar, header, 'OBT-END',trim(string(obt_end)),'End of acquisition time in OBT'
  sxaddpar, header, 'TIMESYS','OBT','System used for time keywords'
  sxaddpar, header, 'DATE-OBS','YYYY-MM-DDThh:mm:ss.SSS','nominal UT date when integration of this'
  sxaddpar, header, 'DATE-END','YYYY-MM-DDThh:mm:ss.SSS','nominal UT date when integration of this'
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'LEVEL','LL01','Processing level of the data'
  sxaddpar, header, 'CREATOR','mwrfits','FITS creation software'
  sxaddpar, header, 'ORIGIN','Solar Orbiter SOC, ESAC','Location where file has been generated'
  sxaddpar, header, 'VERS_SW','2.4','Software version'
  sxaddpar, header, 'VERSION','201810121423','Version of data product'
  sxaddpar, header, 'COMPLETE',complete_flag,'C if data complete, I if incomplete'
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'OBSRVTRY','Solar Orbiter','Satellite name'
  sxaddpar, header, 'TELESCOP','SOLO/STIX','Telescope/Sensor name'
  sxaddpar, header, 'INSTRUME','STIX','Instrument name'
  sxaddpar, header, 'OBS_MODE',obs_mode,'Observation mode'
  sxaddpar, header, 'XPOSURE',string(fix(integration_time)),'[s] Integration time'
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'HISTORY',history,'Example of SW and runID that created file'

end


function stx_asw2fits, input, filename, _extra=_extra

  ; do some sanity checks
  if n_elements(input) eq 0 then message, 'The input is empty.'
  if not TAG_EXIST(input, 'type') then message, 'There is no type tag in your iput structure.'
  
  status = 0
  type = input.type
  CASE type OF
    'stx_asw_ql_lightcurve': begin
        status = lightcurve2fits(input, filename, _extra=_extra)
    end
    'stx_asw_ql_background_monitor': begin
      
    end
    'stx_asw_ql_flare_flag_location': begin
        status= flareflag2fits(input, filename, _extra=_extra)
    end
    ELSE: message, 'type of structure is not supported.'
  ENDCASE
  
  ; retrun 1 if there was no error
  return, status
end