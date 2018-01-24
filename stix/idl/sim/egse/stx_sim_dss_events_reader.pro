;+
; :description:
;     This procedure saves the array of detector event structers of simulated events, into EGSE file.
;     Supports:
;     Detector event: waiting time 11 bits, detector number 5 bits, pixel 4 bits (0-12), amplitude 12 bits
;     Parameter select event: waiting time 11 bits, empty 5 bits, pixel 4 bits (13), parameter index 3 bits
;     Parameter load event: waiting time 11 bits, detector number 5 bits, pixel 4 bits (14), Parameter value 12 bits
;     Dummy event: waiting time 11 bits, empty 5 bits, pixel 4 bits (15), empty 10 bits, value 2 bits (2)
;     EOS: empty 16 bits, pixel 4 bits (15), empty 10 bits, value 2 bits (3)
;
; :params:
;     filename             : in, required, type = "string"
;                            name of output data file
;     temperature_events   : out, optional, type = "array of stx_sim_temperature_event structures"
;                            array of structures containing ASIC Temperature sensor information.
;                            structures are defined by the procedure stx_sim_temperature_event__define.pro
;     constant             : in, optional, type = "integer"
;                            The Constant  
;                            default value is 1500                     
;
; :returns:
;   detector events
;
; :example:
;   detector_events = stx_sim_dss_events_reader('sequence.dssevs')
;   detector_events = stx_sim_dss_events_reader('sequence.dssevs', temperature_events=t_evs)
; 
; :history:
;     19-Jun-2015 - Marek Steslicki (Wro), initial release
;     29-Jun-2015 - Marek Steslicki (Wro), supports new event encoding
;     22-Jul-2015 - Laszlo I. Etesi (FHNW), replaced close with free_lun
;     31-Aug-2015 - Marek Steslicki (Wro), event time encoding bug corrected
;
;-   
function stx_sim_dss_events_reader, filename, temperature_events=temperature_events, constant=constant
    
    get_lun,lun
    openr, lun, filename
    number=ulong(0)

    time_step=0.000000020d 
    current_time=-time_step
    default, constant, 1500

    detector_events=list()
    temperature_events=list()
    parameter=0
    temperature_Vref=lonarr(32)
    detector_event_Vref=lonarr(32)

    tt=ulong64(0)
          
    while not eof(lun) do begin
      readu,lun,number
      event_orig=reverse(stx_sim_egse_number2bitarray( number, number_of_bits=32))
      event=reverse([event_orig[24:31],event_orig[16:23],event_orig[8:15],event_orig[0:7]])
      pixel=stx_sim_egse_bitarray2number(event[16:19])
 
     current_time+=(stx_sim_egse_bitarray2number(event[0:10])+1.d)*time_step ; +1 because 0 value is still one time step
     tt+=stx_sim_egse_bitarray2number(event[0:10])+1.d
  
        
      if pixel le 12 then begin
        ; detector event
        
        detector_index=stx_sim_dss_detector_numbering(stx_sim_egse_bitarray2number(event[11:15]))
;        print,current_time,detector_index,pixel,stx_sim_egse_bitarray2number(event[20:31])+constant-detector_event_Vref[detector_index-1] 
 ;       print,event
        detector_events.add,stx_construct_sim_detector_event(relative_time=current_time, $
                                                             detector_index=detector_index, $
                                                             pixel_index=pixel, $
                                                             energy_ad_channel=stx_sim_egse_bitarray2number(event[20:31])+constant-detector_event_Vref[detector_index-1] )
;        print,tt
      endif

      if pixel eq 13 then begin
        ; Parameter selection event
        parameter=fix(stx_sim_egse_bitarray2number(event[20:22]))
      endif

      if pixel eq 14 then begin
        ; load parameter event
        if parameter eq 1 then temperature_Vref[stx_sim_dss_detector_numbering(stx_sim_egse_bitarray2number(event[11:15]))-1]=stx_sim_egse_bitarray2number(event[20:31])
        if parameter eq 2 then begin
          detector_index=stx_sim_egse_bitarray2number(event[11:15])
          temperature_events.add,stx_construct_sim_temperature_event(relative_time=current_time, $
                                                  detector_index=detector_index, $
                                                  temperature=stx_sim_egse_bitarray2number(event[20:31])-temperature_Vref[detector_index-1] )
        endif

        if parameter eq 3 then detector_event_Vref[stx_sim_dss_detector_numbering(stx_sim_egse_bitarray2number(event[11:15]))-1]=stx_sim_egse_bitarray2number(event[20:31])
      endif      

      if pixel eq 15 then begin
        event_type=stx_sim_egse_bitarray2number(event[30:31])
        if event_type eq 2 then begin
          ; dummy event
 ;         print,event[0:10]
 ;         print,tt          
        endif 
        if event_type eq 3 then begin
          ; eos
          break
        endif 
      endif      


      
    endwhile
    
    
    free_lun, lun
    
    if temperature_events.IsEmpty() then begin
        temperature_events=0
        message,'no ASIC Temperature sensor information in the sequence', /inf 
    endif else begin
        temperature_events=temperature_events.ToArray()
        message,'ASIC Temperature sensor information present in the sequence', /inf 
    endelse
    
    return, detector_events.toarray()
    
    
end
