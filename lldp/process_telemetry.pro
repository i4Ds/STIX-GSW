; Request-dir: source of telemetry files
;
; Output-dir: Output/scratch - where 'consolidated_telemetry' will be placed
;
; keep_going: Use tlm object from last time (no rewind to beginning)
;
; reset: when set, existing consolidated telemetry files are deleted
;        (triggering a reprocessing from XML format)
;
;
pro process_telemetry, request_dir, output_dir, keep_going=keep_going, stream=stream, $
  reset=reset, obt_start=obt_start, obt_end=obt_end

  ; We use a common block to ensure that we can destroy the
  ; solo_telemetry object upon reentry
  ;
  common process_telemetry__tlm, tlm

  if not keyword_set(keep_going) then begin
    if obj_valid(tlm) then obj_destroy, tlm
    tlm = solo_telemetry(request_dir, output_dir, reset = reset)
  end

  ; Set up for cycling through packets:
  ;
  bitreader = bitreader()

  ; we use the stx_tmtc_writer (stream, no file)
  tmtc_writer = stx_telemetry_writer(size=2L^24)

  ; start_of_nominal_day determines the point in time at which we should
  ; start producing fits files. First retrieve from tlm object - as hex
  ; string, then extract the Coarse OBT part (32 bits) using bitreader
  ;

  start_of_nominal_day_as_hex = tlm->start_of_nominal_day()
  start_of_nominal_day_as_bin = tlm->bin_packet(start_of_nominal_day_as_hex)
  bitreader->set_data, start_of_nominal_day_as_bin
  obt_start = bitreader->bits(32)

  print, "Starting packet processing"

  start_time = systime(1)
  num_packets = 0L

  while (1) do begin

    ; Next packet; !NULL on EOF, and n_elements(!NULL) EQ 0 => BREAK
    ;
    hex_packet = tlm->hex_packet()
    if n_elements(hex_packet) eq 0 then break  ; n_elements(!NULL) eq 0

    ; Convert hex packet to binary - could've gotten binary form right away
    ; by calling bin_packet() with no parameters.
    ;
    bin_packet = tlm->bin_packet(hex_packet)

    ; Stuff binary data into bitreader object
    ;
    bitreader->set_data, bin_packet

    stx_lldp_parse_packet, bitreader, tmtc_writer, obt=obt, monotony_reset = num_packets eq 0L

    num_packets++
  end

  obt_end = obt
  stream = tmtc_writer->getBuffer(/trim)
  destroy, tmtc_writer 
  obj_destroy, tlm

  time_used = systime(1) - start_time
  average_time = time_used / num_packets
  print,"DONE, num_packets: ",num_packets
  print,"Average time", average_time

end