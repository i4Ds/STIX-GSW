;; Do the actual processing, using output_dir also for scratch
;;
PRO process_request, input_dir, output_dir

  ; initialize environment
  stx_lldp_init_environment
  
  request = file_basename(input_dir)
  print
  print, "PROCESSING: "+request

  ; We get back "obt_start" which is the first OBT in the "current day".
  ;
  process_telemetry, input_dir, output_dir, stream=stream,$
    obt_start=obt_start, obt_end=obt_end


  print
  print, "Pretending to be done"
  print
  print, "Coarse OBT start: ", obt_start
  print, "Coarse OBT end  : ", obt_end
  print, "Duration (secs) : ", obt_end-obt_start
  print
  help, obt_start, obt_end

  print, 'Making dummy fits file using OBT_BEG = OBT start'
  obt_beg = trim(obt_start, '(I010)')

  svn_number = svn_number()
  print, 'SVN number = '+trim(svn_number)
  print
  aux_dir = input_dir + "/auxiliary"
  filename = aux_dir + "/filtered_tmtc.bin"
  tmtc_reader = stx_telemetry_reader(stream=stream)
  
  ; create emtpy lists, in case no data are returned
  asw_ql_lightcurve = list()
  asw_ql_flare_flag_location = list()

  ; create lightcurve and flare_flag_location
  tmtc_reader->getdata, solo_packets = solo_packets_r, statistics = statistics, $
    asw_ql_lightcurve=asw_ql_lightcurve, $
    asw_ql_flare_flag_location=asw_ql_flare_flag_location
  
  ;create lightcurve fits file(s)
  file_nr=0
  first_run=1
  foreach lightcurve, asw_ql_lightcurve do begin
    file_lighcurve = output_dir+'/solo_LL01_stix-lightcurve_'+trim(string(obt_beg))+'_'+trim(string(file_nr))+'.fits'
    if first_run then begin
      file_lighcurve = output_dir+'/solo_LL01_stix-lightcurve_'+trim(string(obt_beg))+'.fits'
      first_run=0
    endif
    err=stx_asw2fits(lightcurve,file_lighcurve,obt_beg=obt_beg,obt_end=obt_end, history=trim(svn_number))
    if err eq 0 then fail=1
  endforeach
  
  ;create flare_flag_location fits file(s)
  file_nr=0
  first_run=1
  foreach flare, asw_ql_flare_flag_location do begin
    file_flare_flag = output_dir+'/solo_LL01_stix-flareinfo_'+trim(obt_beg)+'_'+trim(file_nr)+'.fits'
    if first_run then begin
      file_flare_flag = output_dir+'/solo_LL01_stix-flareinfo_'+trim(obt_beg)+'.fits'
      first_run=0
    endif
    err=stx_asw2fits(flare,file_flare_flag,obt_beg=obt_beg,obt_end=obt_end,history=trim(svn_number))
    if err eq 0 then fail=1
  endforeach

  fail = 0
END
