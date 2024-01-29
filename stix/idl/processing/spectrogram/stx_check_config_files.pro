;+
; :description:
;    This procedure sets the relevant parameters for updating
;    the energy lookup table (ELUT) files
;
; :categories:
;    calibration, configuration
;
; :params:
;    directory : in, required, type="string"
;                path to the directory where the ELUT csv files are stored
;
; :keywords:
;    verbose  :  in, optional, type="Boolean"
;                if files are to be downloaded sock_copy is called with the verbose keyword
;
; :history:
;    31-Aug-2023 - ECMD (Graz), initial release
;
;-
pro stx_update_elut, directory, verbose = verbose

  url_root = 'http://dataarchive.stix.i4ds.net/STIX-CONF/elut/'
  name_idx = 'elut_index.csv'
  filter = 'elut_table*csv'

  stx_update_det_config_files, url_root = url_root, name_idx = name_idx, filter = filter, directory = directory

end

;+
; :description:
;    This procedure sets the relevant parameters for updating
;    the science energy channel files
;
; :categories:
;    calibration, configuration
;
; :params:
;    directory : in, required, type="string"
;                path to the directory where the Science Energy Channels csv files are stored
;
; :keywords:
;    verbose  :  in, optional, type="Boolean"
;                if files are to be downloaded sock_copy is called with the verbose keyword
;
; :history:
;    31-Aug-2023 - ECMD (Graz), initial release
;
;-
pro stx_update_echan, directory, verbose = verbose

  url_root = 'http://dataarchive.stix.i4ds.net/STIX-CONF/detector/'
  name_idx = 'science_echan_index.csv'
  filter = 'ScienceEnergyChannels*csv'

  stx_update_det_config_files,  url_root = url_root, name_idx = name_idx, filter = filter, directory = directory, verbose = verbose

end

;+
; :description:
;    This procedure updates the detector configuration files
;
; :categories:
;    calibration, configuration
;
;
; :keywords:
;    url_root : in,  required, type="string"
;               the GitHub URL for the folder where the requested config files are available
;
;    name_idx : in,  required, type="string"
;               the name of the index file for the requested configuration
;
;    filter : in, required, type="string"
;               specify the filenames of the configuration files in format compatible with find_file.pro
;
;    directory : in, required, type="string"
;               path to the directory where the configuration files are stored
;               
;    verbose  :  in, optional, type="Boolean"
;                if files are to be downloaded sock_copy is called with the verbose keyword         
;
; :examples:
;    stx_update_det_config_files, url_root = 'https://github.com/i4Ds/STIX-CONF/raw/main/elut/', name_idx = 'elut_index.csv', $
;                                 filter = 'elut_table*csv', directory = getenv('STX_DET')
;
; :history:
;    31-Aug-2023 - ECMD (Graz), initial release
;
;-
pro stx_update_det_config_files,  url_root = url_root, name_idx = name_idx, filter = filter, directory = directory, verbose = verbose

  url_idx = url_root + name_idx

  sock_copy, url_idx, out_dir = directory, local_file = local_file, /clobber, verbose = verbose

  str_index = read_csv(local_file, n_table_header = 1)
  elut_filenames = (str_index.field4)

  files_present = find_file(concat_dir(directory, filter), count = count)
  filenames_present = file_break(files_present, /name)

  for i = 0, n_elements(elut_filenames)-1 do begin
    check =  where(elut_filenames[i] eq filenames_present, count_found)
    if count_found eq 0 then begin
      url = url_root + elut_filenames[i]
      sock_copy, url, out_dir = directory, verbose = verbose
    endif

  endfor



end


;+
; :description:
;    This procedure checks the latest version of the STIX-CONF folder in the data archive 
;    and determines if the elut and echan files need to be updated.  
;
; :categories:
;    calibration, configuration 
;
; :params:
;    directory : in, required, type="string"
;            path to directory where config files are stored, should usually be /ssw/so/stix/dbase/detector
;            
; :keywords:
;    verbose  :  in, optional, type="Boolean", default = 0
;                if files are to be downloaded sock_copy is called with the verbose keyword
;                            
; :examples:
;    stx_check_config_files, getenv('STX_DET')
;
; :history:
;    31-Aug-2023 - ECMD (Graz), initial release
;    22-Jan-2024 - Use Dominic Zarro's <idlneturl2> __define in place of out of box IDL idlneturl
;
;-
pro stx_check_config_files, directory, verbose = verbose
  default, directory, getenv('STX_DET')
  default, verbose, 0
  
  run_update = 0
  net  = have_network()
  if net eq 0 then begin
    print, 'Network unavailable. Configuration files such as ELUTs may be outdated.'
  endif else begin
    version_file = concat_dir(directory, 'stix_conf_version.txt')
    find_version_file = loc_file(version_file)

      ourl = obj_new('IDLnetURL2')     ; S.L.Freeland - use Dominic's IDLnetURL2[__define].pro in place of IDL intrinsic
      callback_data = ptr_new({loc:''})
      ourl->setproperty, url_scheme='http'
      ourl->setproperty, url_host='dataarchive.stix.i4ds.net'
      ourl->setproperty, url_path='/STIX-CONF/VERSION.TXT'

      online_version = ourl->get(/string)
      
     if find_version_file ne '' then begin
        readcol, find_version_file, current_version, format = 'a', /silent
       if current_version eq online_version then print,'STIX Configuration files are already up to date ' + online_version else run_update =  1 
      endif else run_update =  1 
      
    if run_update then begin

      stx_update_elut, directory, verbose = verbose
      stx_update_echan, directory, verbose = verbose

      ;update version file
      str2file, online_version, version_file
    endif
  endelse

end
