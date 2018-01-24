;+
; :description:
;     This function converts a event data to ulong number in the egse event format
;
; :params:
;     amplitude            : in, optional, value of amplitude
;     pixel                : in, optional, pixel number
;     detector             : in, optional, detector number
;     time                 : in, time of event, number 20ns intervals, max 2048 (11 bit)
;     parameter_selection  : in, optional,
;     parameter_value      : in, optional,
;     type                 : in, optional, type of data: 
;                               - detector event (detector_event) - default, 
;                               - Parameter selection (parameter_selection), 
;                               - Parameter value (parameter_value), 
;                               - Dummy event (dummy), 
;                               - End Of Sequence event (eos)
;                               
; :Keywords:
;     loud                 :  turns on messages               
;                               
; :returns:
;     output   :  ulong number which can be saved as a EGSE event
; 
; :example:
;     egse_detector_event=stx_sim_egse_event(amplitude=amplitude_value, pixel=pixel_index, detector=detector_index, time=waiting_time )
;     egse_dummy_event=stx_sim_egse_event( time=time,type='dummy' )
; 
; :history:
;     02-Jul-2015 - Marek Steslicki (SRC Wro), new DSS evenet encoding supported
;     06-Feb-2015 - Marek Steslicki (Wro), initial release
;
;-

function stx_sim_dss_event, amplitude=amplitude, parameter_selection=parameter_selection, parameter_value=parameter_value, temperature=temperature, pixel=pixel,detector=detector,time=time,testpulse=testpulse,sensor=sensor,type=type, loud=loud 

      event=ulong(0)
  
    if not keyword_set(type) then begin
      if keyword_set(loud) then message, 'Type of data not defined. Using "detector_event" type', /INF
      type='detector_event' 
    endif


  if keyword_set(detector) then detector=stx_sim_dss_detector_numbering( detector, /dss)

; creation of the bit array of an event
  case type of
      'parameter_selection' : begin
            time_barr=stx_sim_egse_number2bitarray(time, number_of_bits=11)
            detector_barr=stx_sim_egse_number2bitarray(0, number_of_bits=5)
            pixel_barr=stx_sim_egse_number2bitarray(13, number_of_bits=4)
            empty_barr=stx_sim_egse_number2bitarray(9, number_of_bits=9)
            par_barr=stx_sim_egse_number2bitarray(parameter_selection, number_of_bits=3)
            event_barr=[time_barr,detector_barr,pixel_barr,par_barr,empty_barr]
            end       
       'parameter_value' : begin
            time_barr=stx_sim_egse_number2bitarray(time, number_of_bits=11)
            detector_barr=stx_sim_egse_number2bitarray(detector, number_of_bits=5)
            pixel_barr=stx_sim_egse_number2bitarray(14, number_of_bits=4)
            parameter_barr=stx_sim_egse_number2bitarray(parameter_value, number_of_bits=12)
            event_barr=[time_barr,detector_barr,pixel_barr,parameter_barr]
            end             
      'dummy': begin
            time_barr=stx_sim_egse_number2bitarray(time, number_of_bits=11)
            detector_barr=stx_sim_egse_number2bitarray(0, number_of_bits=5)
            pixel_barr=stx_sim_egse_number2bitarray(15, number_of_bits=4)
            empty_barr=stx_sim_egse_number2bitarray(0, number_of_bits=10)
            nr_barr=stx_sim_egse_number2bitarray(2, number_of_bits=2)
            event_barr=[time_barr,detector_barr,pixel_barr,empty_barr,nr_barr]
            end

      'eos': begin
            time_barr=stx_sim_egse_number2bitarray(time, number_of_bits=11)
            detector_barr=stx_sim_egse_number2bitarray(0, number_of_bits=5)
            pixel_barr=stx_sim_egse_number2bitarray(15, number_of_bits=4)
            empty_barr=stx_sim_egse_number2bitarray(0, number_of_bits=10)
            nr_barr=stx_sim_egse_number2bitarray(3, number_of_bits=2)
            event_barr=[time_barr,detector_barr,pixel_barr,empty_barr,nr_barr]
            end


      else: begin
            time_barr=stx_sim_egse_number2bitarray(time, number_of_bits=11)
            detector_barr=stx_sim_egse_number2bitarray(detector, number_of_bits=5)
            pixel_barr=stx_sim_egse_number2bitarray(pixel, number_of_bits=4)
            amplitude_barr=stx_sim_egse_number2bitarray(amplitude, number_of_bits=12)
            event_barr=[time_barr,detector_barr,pixel_barr,amplitude_barr]
            end
   endcase
   
   event_barr=reverse(event_barr)

; reverse invidual bytes   
   event_barr_ok=[reverse(event_barr[0:7]),reverse(event_barr[8:15]),reverse(event_barr[16:23]),reverse(event_barr[24:31])]

; convert to the ulong number   
   for i=0,31 do event+=event_barr_ok[i]*ulong(2)^i
   
;   print,event_barr_ok
   
   
   return,event   
end


