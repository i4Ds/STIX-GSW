;+
; :Name:
;   stx_demo_tmtc
;   
; :Description:
;    Demo of the telemetry routines.
;    More details: https://stix.cs.technik.fhnw.ch/confluence/display/STX/TMTC
;
; :Categories:
;    simulation, reader, telemetry
;
; :Examples:
; This is working example :) stx_demo_tmtc
; 
; :Keywords:
;    run_fsw            - runs run_ds_fswsim_demo instead of loading a sav-file.
;    scenario           - specifies the scenario for run_ds_fswsim_demo
;    nbr_random_packets - number of random packets to generate for each packet type
;
; :History:
;     24-Nov-2015 - Simon Marcin (FHNW), initial release
;     28-Jun-2016 - Simon Marcin (FHNW), changed demo to use stx_fsw_ql_lightcurve structure
;     15-Sep-2016 - Simon Marcin (FHNW), added flare_flag_location and ql_variance
;     19-Sep-2016 - Simon Marcin (FHNW), added ql_spectra
;     13-Oct-2016 - Simon Marcin (FHNW), added ql_energy_calibration
;     21-Dec-2016 - Simon Marcin (FHNW), added missing packets, added keywords, changed structure
;-

pro stx_demo_tmtc, run_fsw=run_fsw, scenario=scenario, nbr_random_packets=nbr_random_packets
  default, run_fsw, 0
  default, scenario, 'stx_scenario_2'
  default, nbr_random_packets, 10
  
  
  ;---------------------------- Load FSW data ---------------------------
  ;construct file names
  fsw_file = 'stix\idl\demo\sav\'+scenario+'_fsw.sav'
  dss_file = 'stix\idl\demo\sav\'+scenario+'_dss.sav'
  ivs_file = 'stix\idl\demo\sav\'+scenario+'_ivs.sav'

  ; run fsw if either files are missing or forced by keyword
  if run_fsw or not FILE_TEST(fsw_file) then begin
      run_ds_fswsim_demo, fsw=fsw, dss=dss, scenario=scenario
      save, fsw, file=fsw_file
      save, dss, file=dss_file
      ; interval selection (whole time range)
      fsw->getproperty, RELATIVE_TIME=rel_time
      flare_time = {$
          type            : "stx_fsw_flare_selection_result", $
          IS_VALID        : 1b, $
          FLARE_TIMES     : reform([stx_construct_time(time=0.0),stx_construct_time(time=rel_time)],1,2), $
          CONTINUE_TIME   : stx_time() $
      }
      fsw->set, module="stx_fsw_module_intervalselection_img", trimming_max_loss = 0.0d
      ivs_result = fsw->getdata(output_target="stx_fsw_ivs_result", input_data=flare_time)
      save, ivs_result, file=ivs_file  
  endif else begin
    restore, file=fsw_file
    restore, file=dss_file
    restore, file=ivs_file
  endelse


  ;----------------- Get or create structures from fsw/ivs and pass to TMTC writer ----------------
  ; create TMTC witer object
  tmtc_writer = stx_telemetry_writer(filename='tmtc_packets.bin')
  
  ; get all quicklook and science data products out of fsw and ivs (useing standard compression values)
  bulk_data = stx_telemetry_util_fsw2tmtc(fsw=fsw, ivs=ivs_result)
  tmtc_writer->setdata, bulk_data=bulk_data
  
  ;instead of bulk data you can also set individual data products
  ; https://stix.cs.technik.fhnw.ch/confluence/display/STX/TMTC
  
  ; create random data for unavailalbe products
  for i=0, nbr_random_packets-1 do begin
    report_mini=stx_asw_hc_regular_mini(/random)
    report_maxi=stx_asw_hc_regular_maxi(/random)
    heartbeat = stx_asw_hc_heartbeat(/random)
    flare_list=stx_asw_ql_flare_list(/random)
    tmtc_writer->setdata, hc_regular_mini=report_mini
    tmtc_writer->setdata, hc_regular_maxi=report_maxi
    tmtc_writer->setdata, hc_heartbeat=heartbeat
    tmtc_writer->setdata, ql_flare_list=flare_list
  endfor
  
  ; get all packets in the intermediate format (good for troubleshooting)
  tmtc_writer->setdata, solo_packets=solo_packets_write
  
  ; write to disk
  destroy, tmtc_writer
  
  
  ;----------------- Read the telemetry file ----------------
  ; create the telemetry reader object (scan mode only reads the headers of the packets)
  tmtc_reader = stx_telemetry_reader(filename='tmtc_packets.bin', /scan_mode)

  ; get some statistics about the TMTC file.
  tmtc_reader->getdata, statistics = statistics
  print, statistics

  ; getdata all data products in a Hash
  tmtc_reader->getdata, bulk_data=bulk_data_read
  
  ; you could also access each product like this:
  tmtc_reader->getdata, asw_ql_variance=asw_ql_variance
  tmtc_reader->getdata, asw_ql_lightcurve=asw_ql_lightcurve
  ; .... (see keywords of tmtc_reader->getdata)
  
  ; get all packets in the intermediate format (good for troubleshooting)
  tmtc_reader->getdata, solo_packets=solo_packets_read
 
  ; destroy reader object
  destroy, tmtc_reader
  
   stop
end