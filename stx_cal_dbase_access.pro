
;+
; :Description:
;    Build and send a request/query to the pub023 server, and return the
;    parsed reply and data array for the calibration_spectrum and processed results
; :Examples:
;  IDL> print, fr[0]
;  solo_L1_stix-calibration-spectrum_20200414T130357__complete_00100.fits
;  IDL> data = stx_cal_dbase_access( fr[0], q = qstr )
;  IDL> help, qstr
;  ** Structure <15513440>, 5 tags, length=48, data length=48, refs=1:
;     FITS_FILE_ID    LONG64                       100
;     CALIBRATION_RUN_ID
;                     LONG64                       234
;     RAW_FILE_ID     LONG64                        82
;     MEAS_START_UTC  STRING    '2020-04-14T13:03:57.158'
;     DURATION_SECONDS
;                     LONG64                      1800
;  IDL> help, data
;  DATA            DOUBLE    = Array[35, 384]
; :Params:
;    input - qlook calibration spectrum FITS filename
;
; :Keywords:
;    query_struct - parsed results from the query relating the FITS file and the calibration run
;    
;
; :Author: rschwartz70@gmail.com
; :History: Version 1, 6-aug-2020 75th anniversary of atomic bomb on Hiroshima
;-
function stx_cal_dbase_access, filnam, query_struct = query_struct

  if is_string(filnam) && stregex( filnam,/boo,/fold,'fits')then begin ;it's a full filename, the fits_file_id is at the end
    sl = strlen(filnam)
    input = strmid( filnam,sl-10,5)

  endif
  type  = 'query' 
  class =  'fits/' 
;      IDL> base
;    http://stix:!SOL_stix!@pub023.cs.technik.fhnw.ch/

  base = stx_pub023_query_base()
  url = base  + type + '/calibration/'+class + strtrim(input,2)
  sock_list, url, out

  data = 0
  if keyword_set(out) then begin
    query_struct = (json_parse( out,/tostruct))[0]
    run = query_struct.calibration_run_id
    type = 'request'
    class = 'elut/'
    url = base + type + '/calibration/'+class + strtrim(run,2)
    sock_list, url, out
    if keyword_set(out ) && out[0] ne '[]' then data = json_parse( out, /toarray,/tostruct)

  endif
  return, data
end
;Development notes
;;1) Find the fits file for a calibration run
;
;JSON API:
;http://pub023.cs.technik.fhnw.ch/query/fits/calibration/<CALIBRATION_RUN_ID>
;
;For example:
;http://pub023.cs.technik.fhnw.ch/query/fits/calibration/900
;
;it will return a json string as below:
;
;[
;{
;"calibration_run_id":  900,
;"raw_file_id":204,
;"fits_filename":"solo_L1_stix-calibration-spectrum_20200519T003857__complete_03338.fits",
;"fits_file_id":3338,
;"packet_start_id":635146,
;"packet_end_id":635176,
;"is_complete":true,
;"meas_start_utc":"2020-05-19T00:38:57.245",
;"meas_end_utc":"2020-05-19T00:53:57.245",
;"duration_seconds":900.0,
;"fits_creation_time":{
;"$date":1595458101975
;}
;}
;]
;2) Find the calibration run for a fits file
;
;JSON API:
;http://pub023.cs.technik.fhnw.ch/query/calibration/fits/<FITS_FILE_ID>
;
;
;http://pub023.cs.technik.fhnw.ch/query/calibration/fits/3338
;
;returns
;
;[{"fits_file_id": 3338, "calibration_run_id": 900, "raw_file_id": 204, "meas_start_utc": "2020-05-19T00:38:57.155", "duration_seconds": 900}]
;
;
;The last 5-digit number in a filename indicates its fits file id.
;For example, the fits file id of the following file is  3338.
;solo_L1_stix-calibration-spectrum_20200519T003857__complete_03338.fits
;
;
;Are they want you want?
;best regards
;Hualin Xiao
;
;On 8/3/20 2:49 AM, Richard Schwartz wrote:
;How do I find the Run# for each calibration spectrum FITS file so I can associate the results with the data?
;What is the link between the two without having to look at each spectrum in the browser?  I can see that there may be more than one calibration run on a given file.
;Thanks
;Richard
;
;On Sat, Aug 1, 2020 at 3:11 PM Hualin Xiao <hualin.xiao@fhnw.ch> wrote:
;http://pub023.cs.technik.fhnw.ch//request/calibration/elut/<ELUT_NUMBER>
;
;for example:
;
;http://pub023.cs.technik.fhnw.ch//request/calibration/elut/992
;
;
;
;On 8/1/20 9:07 PM, Richard Schwartz wrote:
;What is the API to request the elut_run_###.csv files?
;Thanks
;Richard
;
;On Thu, Jul 23, 2020 at 5:07 AM Hualin Xiao <hualin.xiao@fhnw.ch> wrote:
;Dear All,
;
;A L1 fits data product database now is available on pub023 server.
;The data request APIs can be found in the attached pdf file.
;In addition to the APIs, one could also use the following web tools to search for L1 fits products:
;
;1) FITS file web manager
;http://pub023.cs.technik.fhnw.ch/view/list/fits
;
;2) To search for /download data request fits products
;http://pub0o23.cs.technik.fhnw.ch/view/list/bsd
;
;3) To search for fits products for telemetry files:
;
;http://pub023.cs.technik.fhnw.ch/view/list/files
;
;
;Please let me know if you have any comment, suggestion, or find any issue.
;Thanks.
;
;
;best regards
;
;Hualin Xiao
;
;fr = file_search('*calibration*.fits')

;fr = file_basename(fr)

;sl = strlen(fr[0])
;rnum = strmid(fr,sl-10,5)
