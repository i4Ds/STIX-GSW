;+
; :description:
;
;    This function reads an ascii file containing STIX telemetry data and returns the
;    contained data of the specified packet type  in the standard format output by stx_telemetry_reader.
;    Optionally the “solo_packets” and “statistics” telemetry reader outputs can also be returned to be used in further processing.
;
;
;
; :categories:
;
;    reader, telemetry
;
; :params:
;
;    file   : in, required, type="string"
;             the path of the ascii file to be read
;
; :keywords:
;
;    packet_type :  in, type="string"
;                   stx_tmtc_structure name for type of packet to be read
;
;    tstart      : in, type="string", default= time stamp of first line in the file
;                  the earliest time stamp to use when looking for packets
;
;    tend        : in, type="string", default= time stamp of last line in the file
;                  the latest time stamp to use when looking for packets
;
;    uselines    : out, type="list"
;                  the lines of the file which correspond to the specified packets
;
;    solo_packets  : out, type = "hash"
;                    solar orbiter packets output from stix telemetry reader
;
;    statistics    : out, type = "hash"
;                    statistics output from stix telemetry reader
;
;
;    verbose       : in, optional, type='boolean'
;                  if set to 1, it will print the key header information for each line read
;                  will also be passed to stx_telemetry_reader which will print info about the processed packets
;
; :returns:
;
;   data_out  :  a list containing the structures for input packet type for all corresponding packets found in the file
;
; :restrictions:
;
;     - The ASCII file must be in the format output by the SIIS
;       "time" "packet content in ascii hexadecimal format"
;       e.g
;       2019-10-01T11:11:28.767Z 0DDCC0100014101506009619AF9E34012B00000000000693D90000
;
;     - The desired packet type must be specified in tmtc_packet_mapping.csv
;
;
; :examples:
;
;      filename = concat_dir(concat_dir( concat_dir('SSW_STIX','dbase'),'demo'), 'stx_gu_calibration_test_20191001.txt')
;      calibration_spectrum = stx_read_ascii_single_packet_type( filename, packet_type= 'stx_tmtc_ql_calibration_spectrum' )
;
;
; :history:
;    25-Oct-2019 - ECMD (Graz), initial release
;
;-
function stx_read_ascii_single_packet_type, file, tstart = tstart, tend = tend, packet_type = packet_type, uselines = uselines, solo_packets = solo_packets,$
  statistics = statistics, verbose = verbose

  ;default file is test telemetry from the ground unit
  default, file , concat_dir(concat_dir( concat_dir('SSW_STIX','dbase'),'demo'), 'gu_calibration_test/stx_gu_calibration_test_20191001.txt')

  ;default packet type
  default, packet_type, 'stx_tmtc_ql_calibration_spectrum'

  ; get the recognised packet types from tmtc_packet_mapping.csv
  mappings = stx_read_tmtc_mapping()

  ;make sure the input string for requested packet type matches something in the mapping
  vaild_type = where(mappings.stx_tmtc_str eq packet_type, n_valid_type)

  ; if nothing matches message the user and return !null
  if n_valid_type eq 0 then begin
    message, 'Input packet type not recognised. Currently recognised types are: '+ (mappings.stx_tmtc_str).join(', '), /info
    return, !NULL
  endif


  nlines = file_lines(file)

  ;read through the whole file converting each line into a string
  openr, lun, file, /get_lun
  array = strarr(2,nlines)
  line = ''

  ;the time stamp is a fixed length of 24 characters so read that into on string
  ; after a space the rest of the line contains the packet contents so that is read
  ;into a separate string
  for i =0 ,nlines-1 DO BEGIN
    READF, lun, line
    s1 = line.substring(0,23)
    s2 = line.substring(25,-1)
    array[*, i] = [s1,s2]
  endfor

  ; covert the time into anytim format
  time =  anytim(array[0,*])

  ; by default, the time range used spans the full file
  default, tstart, array[0,0]
  default, tend, array[0,-1]

  ; get the indices of the lines which corresponded to the requested time interval
  k = where((time gt anytim(tstart)) and (time lt anytim(tend)), n_lines_time)

  ;
  numall = list()
  uselines = list()
  usedpackets = list()
  timeout =list()


  for i = 0l, n_lines_time-1 do begin

    line = array[1,k[i]]

    ;each byte is encoded as a pair of ascii characters
    n_hex = strlen(line)/2

    numout = bytarr(n_hex)

    num0 = 0b
    num1 = 0b
    packet_service = 0b
    packet_subservice = 0b
    packet_ssid = 0b

    ; the application process id information in the tm source packet header does not align
    ; with byte (octet) boundaries so convert the first and second bytes separately
    reads,line.substring(0,1), num0, Format='(Z)'
    reads,line.substring(2,3), num1, Format='(Z)'

    ;then convert the first two byes into 16 individual bits
    b = reform(([num0,num1]).tobits(), 16)

    ;the process id is contained in bits 6 to 12
    bin2dec, b[5:11], packet_apid, /q
    ; the packet category is contained in bits 13 to 16
    bin2dec, b[12:15], packet_category, /q

    ;the packet service and subservice are contained in the second and third bytes of the data filed header
    ; 7th and 8th bits of the full packet respectively
    reads,line.substring(14,15), packet_service, Format='(Z)'
    reads,line.substring(16,17), packet_subservice, Format='(Z)'

    ; some packets are too short to contain an ssid
    if line.Strlen() ge 33 then begin
      reads,line.substring(32,33), packet_ssid, Format='(Z)'
    endif else  packet_ssid = 0

    ;print the relevant header information
    if verbose then print, 'apid: ', packet_apid,' service: ', packet_service, ' subservice: 'packet_subservice, ' SSID: ' packet_ssid

    ; check if the packet header information matches any candidates
    ; described in the mapping
    candidate_id = where(mappings.packet_category eq packet_category and $
      mappings.pid eq packet_apid and $
      mappings.service_type eq packet_service and $
      mappings.service_subtype eq packet_subservice and $
      (mappings.sid eq packet_ssid or mappings.ssid eq packet_ssid), n_candidates)

    ; if it doesn't match any recognised packet type go on to the next line of the file
    if n_candidates eq 0 then continue

    ;determine the type the header information corresponds to
    candidate = mappings[candidate_id]
    found_type=candidate.STX_TMTC_STR

    ; if the found type matches the requested type read the packet data
    if found_type eq packet_type then begin

      ; read each pair of chars and covert it to bytes
      for j = 0l, n_hex - 1 do begin
        subString = STRMID(line, 2l*j, 2)
        num = byte(1)
        reads,substring, num, Format='(Z)'
        numout[j] = num
      endfor

      ;record the time, file line number and full packet information of matching packets
      timeout.add,array[0,k[i]]
      uselines.add, i
      numall.add, numout

    endif

  endfor

  ; if no packets of the request type were found in the file message the user and return null
  if numall.LENGTH eq 0 then begin
    message, 'No valid packets of type ' + packet_type + ' found in file '+ file, /info
    return, !NULL
  endif

  ; the list with the full packet information for all packet types can then be converted into a 1d array
  ; to be fed into the telemetry reader as a single stream
  matching_packet_stream = numall.toarray(DIMENSION=1)

  ; the telemetry reader then scans the stream and stores all the packet info
  telemetry_reader =  stx_telemetry_reader(stream = matching_packet_stream, /scan, verbose = verbose)

  ; as only a single packet type is requested at a time call telemetry_reader->getdata for that type plus
  ; the corresponding solo packets and statistics information
  switch (packet_type) of

    'stx_tmtc_ql_light_curves': begin
      telemetry_reader->getdata, asw_ql_lightcurve = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_ql_background_monitor': begin
      telemetry_reader->getdata, asw_ql_background = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_ql_variance': begin
      telemetry_reader->getdata, asw_ql_variance = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_ql_calibration_spectrum': begin
      telemetry_reader->getdata, asw_ql_calibration_spectrum = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_ql_spectra': begin
      telemetry_reader->getdata, fsw_m_ql_spectra = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_sd_aspect': begin
      telemetry_reader->getdata, fsw_m_sd_aspect=data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_ql_flare_flag_location' : begin
      telemetry_reader->getdata, fsw_m_coarse_flare_locator=coarse_flare_location, fsw_m_flare_flag=flare_flag, solo_packets = solo_packets, statistics = statistics
      data_out = {coarse_flare_location:coarse_flare_location, flare_flag:flare_flag}
      break
    end

    'stx_tmtc_ql_flare_list' : begin
      telemetry_reader->getdata, asw_ql_flare_list = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_sd_xray_0': begin
      telemetry_reader->getdata, fsw_archive_buffer_time_group = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_sd_xray_1': begin
      telemetry_reader->getdata, fsw_pixel_data_time_group = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_sd_xray_2': begin
      telemetry_reader->getdata, fsw_pixel_data_summed_time_group = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_sd_xray_3': begin
      telemetry_reader->getdata, fsw_visibility_time_group=data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_sd_spectrogram': begin
      telemetry_reader->getdata, fsw_spc_data_time_group = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_hc_heartbeat' : begin
      telemetry_reader->getdata, asw_hc_heartbeat = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_hc_regular_mini' : begin
      telemetry_reader->getdata,  asw_hc_regular_mini = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_hc_regular_maxi' : begin
      telemetry_reader->getdata, asw_hc_regular_maxi = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    'stx_tmtc_hc_trace' : begin
      telemetry_reader->getdata, asw_hc_trace = data_out, solo_packets = solo_packets, statistics = statistics
      break
    end

    else: begin
      print, packet_type ,' not read'
    end
  endswitch

  ;return the list received from the telemetry reader containing the full data for all read packets
  return, data_out

end
