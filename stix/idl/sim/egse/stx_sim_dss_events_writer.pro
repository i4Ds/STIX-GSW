;+
; :description:
;     This procedure saves the array of detector event structers of simulated events, into EGSE file.
;
; :params:
;     filename             : in, required, type = "string"
;                            name of output data file
;     detector_events      : in, required, type = "array of stx_sim_detector_event structures"
;                            array of structures containing parameters of the simulated events.
;                            structures are defined by the procedure stx_sim_detector_event__define.pro
;     constant             : in, optional, type = "ulong"
;                            The Constant (default 1500)
;     detector_events_vref : in, optional, type = "ulong" or "array of stx_sim_detector_event structures"
;                            sets up the reference current. 
;                            If it is constant number sets it up at the beginning of the sequence for all detectors
;                            If it is array of structures sets it up in the times and for the detectors given in the structure
;
; :example:
;   stx_sim_detector_events_egse_writer, 'filename.egse', detector_events_array
;   stx_sim_detector_events_egse_writer, 'filename.egse', detector_events_array, detector_events_vref=2024
; 
; :history:
;     02-Mar-2015 - Marek Steslicki (SRC Wro), initial release
;     02-Jul-2015 - Marek Steslicki (SRC Wro), new DSS evenet encoding supported
;     08-Jul-2015 - Marek Steslicki (SRC Wro), Vreff array indexing bug fixed
;     09-Jul-2015 - Marek Steslicki (SRC Wro), larger (then 32767) number of events supportet (max ulong64) 
;     22-Jul-2015 - Laszlo I. Etesi (FHNW), replaced close with free_lun
;
;-

pro stx_sim_dss_events_writer,  filename, detector_events, constant=constant, detector_events_vref=detector_events_vref

    default, constant,1500
    default, detector_events_vref, 2000 
    
    get_lun,lun
    openw, lun, filename, append=append

    n_de=n_elements(detector_events)

      time_step=0.000000020d  ; 20 ns in seconds
;      time_step=0.000000020d*1000d  ; 20 ns in miliseconds
;      time_step=20l   ; 20 ns in nanoseconds

      curr_vref_value=lonarr(32)

      block_size=ulong64(256)
      n_of_events_to_save=ulong64(4096)
      n_of_events_saved_in_block=ulong64(0)


      detector_events_vref_type=size(detector_events_vref)
      
      ; if detector_events_vref is a single number set this Vref on all detecrors
      if detector_events_vref_type[0] eq 0 then begin
        vref_value=detector_events_vref
        detector_events_vref=list()
        for i=1,32 do begin
          detector_events_vref.add,stx_construct_sim_detector_event(relative_time=(i*2.d -1.d)*time_step, detector_index=i, pixel_index=0, energy_ad_channel=vref_value )
        endfor
        detector_events_vref=detector_events_vref.toarray()
      endif

      n_de_vref=n_elements(detector_events_vref)
      par_set_event_time=dblarr(n_de_vref)
      for i=ulong64(0),n_de_vref-1 do begin
        par_set_event_time[i]=detector_events_vref[i].relative_time-time_step
      endfor
        

      time_saturation=long64(2047)
      last_time_point=ulong64(0)
      previous_time_point=ulong64(0)

      

; list of all events
      n_events=ulong64(n_de)+ulong64(2)*ulong64(n_de_vref)
      event_type=[(replicate(0,n_de)),(replicate(1,n_de_vref)),(replicate(2,n_de_vref))]
      event_index=[(indgen(n_de,/ul64)),(indgen(n_de_vref,/ul64)),(indgen(n_de_vref,/ul64))] 
      event_time=[ detector_events[*].relative_time, par_set_event_time[*], detector_events_vref[*].relative_time ]
      waiting_time=replicate(ulong64(0),n_events+ulong64(1))



; sorting the events by time      
      sorted_events_ind=sort(event_time)
      event_type=event_type[sorted_events_ind]
      event_index=event_index[sorted_events_ind]
      event_time=event_time[sorted_events_ind]


      waiting_time[0]=ulong64((event_time[0])/time_step-0.5d)
      if waiting_time[0] lt 0 then waiting_time[0]=0
      current_time=(waiting_time[0])*time_step

; make the waiting time table in the time steps      
      for i=ulong64(1),n_events-1 do begin
;        time_diference=(event_time[i]-event_time[i-1])/time_step
        time_diference=(event_time[i]-current_time)/time_step
        if time_diference lt 0.5d then begin
          time_diference=1d
 
 ;         print,i,n_events-1
 ;         print,event_time[i],current_time

          message, 'simultaneous or unsorted events', /inf
        endif
        waiting_time[i]=ulong64(time_diference-0.5d)
        current_time+=(waiting_time[i]+ulong64(1))*time_step
      endfor

      n_dummies=ulong64(0)

      tt=ulong64(0)
      i=ulong64(0)
      
      while i lt n_events do begin

      current_waiting_time=ulong64(waiting_time[i]) ; waiting time before this event

;                print,current_waiting_time

; if the current_waiting_time is greater then time_saturation, fill up sequence with 'dummies'
        while current_waiting_time gt time_saturation do begin
          saved_time=time_saturation
          current_waiting_time-=saved_time+1
          writeu,lun,stx_sim_dss_event(time=saved_time,type='dummy')
          n_dummies++
          n_of_events_saved_in_block=((n_of_events_saved_in_block+1) mod block_size)
          if n_of_events_to_save gt 0 then n_of_events_to_save--
        endwhile

        case event_type[i] of
          0: begin
;                print,'ev'
                val=detector_events[event_index[i]].energy_ad_channel-constant+curr_vref_value[detector_events[event_index[i]-1].detector_index-1]
                writeu,lun,stx_sim_dss_event(amplitude=val,pixel=detector_events[event_index[i]].pixel_index,detector=detector_events[event_index[i]].detector_index,time=current_waiting_time)
             end 
          1: begin
              writeu,lun,stx_sim_dss_event(time=current_waiting_time,parameter_selection=3,type='parameter_selection')
             end
          2: begin
              writeu,lun,stx_sim_dss_event(parameter_value=detector_events_vref[event_index[i]].energy_ad_channel,detector=detector_events_vref[event_index[i]].detector_index,time=current_waiting_time,type='parameter_value')
              curr_vref_value[detector_events_vref[event_index[i]].detector_index-1]=detector_events_vref[event_index[i]].energy_ad_channel
             end
        endcase
        i++
        n_of_events_saved_in_block=((n_of_events_saved_in_block+1) mod block_size)
        if n_of_events_to_save gt 0 then n_of_events_to_save--


                
      endwhile

; 
      
      if n_of_events_to_save gt 1 then begin
        while n_of_events_to_save gt 1 do begin
          writeu,lun,stx_sim_dss_event(time=0,type='dummy')
          n_of_events_to_save--
        endwhile
      endif else begin
        while n_of_events_saved_in_block lt block_size-1 do begin
          writeu,lun,stx_sim_dss_event(time=0,type='dummy')
          n_of_events_saved_in_block++
        endwhile        
      endelse
      
      writeu,lun,stx_sim_dss_event(time=0,type='eos')

      free_lun, lun
      
      
end
