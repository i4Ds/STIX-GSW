pro stx_calibration_spectrum_demo
  ; create an empty calibration spectrum structure
  calibration_spectrum = stx_sim_calibration_spectrum()

  ; fill calibration spectrum counts with a pattern
  calibration_spectrum.accumulated_counts = 1

  ; create a big enough buffer and set the writer to a file
  tmw = stx_telemetry_writer(filename='tmtc_test_1.bin', size=2L^24)
  
  ; prepare the SolO packet header and pass in information on the QL calibration spectrum
  solo_packet = tmw->prepare_packet_structure_source_packet_header( $
    calibration_spectrum=calibration_spectrum, $
    data_packet_type='stx_telemetry_packet_structure_ql_calibration_spectrum', $
    subspectra_definition=[[0,4,8], [32,16,8], [160,4,128]], $;, [0,1024,1]], $
    pixel_mask=[0,1,0,0,0,1,0,0,1,0,0,1], $ ;[1,1,1,1,1,1,0,1,1,1,1,1], $;[0,0,0,0,0,0,0,0,0,0,0,1],
    detector_mask=[1,0,1,0,1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0]) ;[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1])
    
  ; write the SolO packet (incl. QL calibration spectrum
  tmw->write_packet_structure_source_packet_header, solo_source_packet_header_structure=solo_packet
  
  ; flush the buffer to disk (force writing of the TMTC file)
  tmw->flushtofile
  
  ; destroy writer to free luns
  destroy, tmw

  ; create the telemetry reader object
  tmr = stx_telemetry_reader(filename='tmtc_test_1.bin')

  ; prepare a container to hold all separate SolO packets with the different QL calibration spectrum splits
  all_solo_packets = list()

  ; process all splits
  while (tmr->have_data()) do begin
    solo_packet = tmr->read_packet_structure_source_packet_header()
    all_solo_packets->add, solo_packet
  endwhile
  
  restore, 'solo_packets_write.sav'
  stx_telemetry_print_all, all_solo_packets->toarray(), file='solo_packet_read.txt', /noref
  stx_telemetry_print_all, solo_slices, file='solo_packet_written.txt', /noref

end