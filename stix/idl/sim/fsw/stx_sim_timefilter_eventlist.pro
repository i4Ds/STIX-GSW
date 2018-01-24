;+
; :description:
;   applies a time filtering to a eventlist
;   according to the "STIX Event Coincident Logic"
;   see: https://stix.cs.technik.fhnw.ch/jira/browse/STX-136   
;
; :params:
;   stx_sim_detector_events:  
;                   in, required, type="stx_sim_detector_events"
;                   a flat array of time orderd stx_sim_detector_events
;
; :keywords:
; 
;   triggers_out:   out, optional, type="stx_sim_event_trigger"
;                   the generated list of event triggers
;                   
;    T_L :         in, type="double", optional, default="2.7 microseconds"
;                  the latency time for the detector coincidence time filtering
;                   
;    T_R :         in, type="double", optional, default="18.80 microseconds"
;                  the readout time for the detector coincidence time filtering
;                  The T_Ignore period occurs at the end of every readout period.
;    T_Ignore:     in, type="double", optional, default="0.720 microseconds"
;                  the Ignore time for the detector coincidence time filtering.
;                  This shortens the veto time of the Readout time.  The effect is to
;                  lengthn the Latency time of any event within the final T_Ignore of any Readout time
;    Event:        the original eventlist with two new tags, 'trigger' set to 1 if it's a trigger
;                  and adgroup_index set according to the det_index adgroup relation
;                  also the event is set to 0 for lost energies from anti-coincidence or
;                  set to the sum of energies for pileup     
;    Pileup_type:  string, case is ignored, default is 'sum' 
;                  'sum'   - photon energies are added, default and normal behavior
;                  'first' - second photon is ignored
;                  'last'  - first photon is ignored
;                  'max'   - larger of two photon energies is used, apparently used in fpga sim                       
;
; :returns:
;    a flat array of remaining stx_sim_detector_events and a list of triggers
;
; :history: 
;   24-feb-2014, nicky.hochmuth@fhnw.ch , initial release
;   11-mar-2014, richard.schwartz@nasa.gov, fixed call to stx_ltpair_assignment
;   18-mar-2014, richard.schwartz@nasa.gov, combined detector/pixel indices into a single index
;   10-sep-2014, richard.schwartz@nasa.gov, allow for sparse data such that there are no events within Tb of each other
;   11-sep-2014, richard.schwartz@nasa.gov, added keyword output structure Event to show the fate of the incoming events
;     explicitly
;   30-nov-2014, Laszlo I. Etesi (FHNW), fixed a possible error by using a count variable set by "where" to control access to an array
;                                        NB: this may have been on purpose
;   19-jan-2015, Laszlo I. Etesi (FHNW), allowing the routine to work with on input event (histogram bugfix -> artificial array)
;   21-sep-2015, richard.schwartz@nasa.gov, added keyword PILEUP_TYPE to conform with FPGA sim software
;   22-sep-2015, laszlo I. Etesi (FHNW), small bugfix (missing comma in the function signature)
;   19-nov-2015, richard.schwartz@nasa.gov, ;19-nov-2015, enter the new possibility. If an event lands within the final T_Ig(nore) then
;                  it can trigger, starting a sequence with a longer latency
;                  So if an event occurs during the T_Ig interval then lengthen the
;                  next T_L by the remaining ignore time which is just the diff between T_B and the elapsed
;                  time from the last trigger
;   21-nov-2015, Laszlo I. Etesi (FHNW), added pileup_type 'last'

;-
function stx_sim_timefilter_eventlist, stx_sim_detector_events, $
  T_L = T_L, T_R = T_R, T_ig = T_ig, $
  triggers_out = triggers_out, event=event, $
  pileup_type = pileup_type
    
;RAS, implementing pileup_type keyword, 21-sep-2015
    default, pileup_type,'sum'
    default, T_L, 2.7d-6 ;2.7 microseconds
    default, T_R, 18.8d-6 ;18.8 microseconds
    default, T_Ig, 0.72d-6 ;720 nanoseconds
    default, T_B, T_L + T_R + T_ig
    
    
    pileup_type = is_string( pileup_type ) ? pileup_type : 'sum'
    pileup_type = is_member( pileup_type, ['sum','first','last','max'], /ignore_case) ? pileup_type : 'sum'
;RAS, 21-sep-2015
    n_event = n_elements(stx_sim_detector_events)
    event   = replicate( { fltr_event, inherits stx_sim_detector_event, $
      ;processed: 0b, $ unnecessary
      adgroup_index: 0b, $
      trigger: 0b }, n_event )
      
    struct_assign, stx_sim_detector_events, event
    event.adgroup_index = stx_ltpair_assignment(event.detector_index, /adgroup_idx) ;not events.detector_index +1
    
    h_adgroup = histogram([event.adgroup_index], min=0, max=16, rev=revi)
    for igroup = 1, 16 do begin
    z = reverseindices( revi, igroup, count=n_ev )
    if n_ev eq 0 then continue
    ev = event[z]
    td = [ev[0].relative_time - 2*T_B, ev.relative_time, ev[ n_ev-1 ].relative_time + 2*T_B ]
    iso = where( ( (td[1:*] - td) < (td[2:*] - td[1:*]) ) / T_B  gt 1, niso, comp = clmp, ncomp= nev_clmp)
    ;ev[iso].processed = 1b
    if(niso gt 0) then ev[iso].trigger   = 1b
    ;process the clumps
    if nev_clmp ge 1 then begin
      evc = ev[clmp]
      energy = evc.energy_ad_channel
      pd_index = evc.detector_index * 100L + evc.pixel_index ;combined unique value for detectors and pixels
      evc.energy_ad_channel = 0 ;clear the energy, only events that survive anti-coinc get energy at the end
      idx = 0L
      T_L_add = 0.0d0 ;extra latency to add from event starting in t_ig at end of T_R
      while idx lt nev_clmp do begin ;for idx = 0L, nev_clmp -1 do begin
        
        idx_tl = idx + 1
        a2d  = energy[idx]
        evc[idx].trigger = 1b ;set the trigger no matter what else happens
        while ( idx_tl lt nev_clmp ) &&  ((evc[idx_tl].relative_time - evc[idx].relative_time) le T_L) do begin
          
              
            if (a2d<1) && (pd_index[idx] eq pd_index[idx_tl]) then begin
  ;        
              ;Pileup, same pixel, same detector, same T_L
              ;RAS, implementing pileup_type keyword, 21-sep-2015
              case pileup_type of 
                'sum'  : a2d += energy[idx_tl]
                'first': a2d = a2d
                'last' : a2d = energy[idx_tl]
                'max'  : a2d >= energy[idx_tl]
                endcase
            endif else begin
              ;Do any events with same group but different pixel-detector occur in the within TL ?
              
              a2d = 0 ;that's the anti-coincidence condition
              ;once you have anti-coincidence, your a2d stays 0 until the next processing clump
            endelse 
          
          idx_tl++ 
        endwhile ;fall out of T_L and check for T_B condition- future anti-coincidence
        ;
        while (idx_tl lt nev_clmp) && $
          ((evc[idx_tl].relative_time - evc[idx].relative_time) le ( T_B - T_Ig ) ) do idx_tl++ ;$ ;begin
        ;we advance the counter without doing anything, these events are therefore ignored
        ;19-nov-2015, enter the new possibility. If an event lands within the final T_Ig(nore) then 
        ;it can trigger, starting a sequence with a longer latency
          
        evc[idx].energy_ad_channel = a2d
        idx_last = idx
        idx = idx_tl
        ;If this new idx event occurs during the T_Ig interval then lengthen the
        ;next T_L by the remaining ignore time which is just the diff between T_B and the elapsed
        ;time from the last trigger
        if (idx lt nev_clmp) then T_L_add = ( T_B - (evc[idx].relative_time - evc[idx_last].relative_time) ) > 0.0d0
      endwhile
      ev[clmp] = evc
      endif
    event[z] = ev
    endfor ;close adgroup
    ztrig = where( event.trigger, ntrig )
    if ntrig gt 0 then begin
      triggers_out =  replicate( {stx_sim_event_trigger}, ntrig ) 
      struct_assign, event[ztrig], triggers_out
      endif else triggers_out = []
    zout = where( event.energy_ad_channel gt 0, nout)
    if nout gt 0 then begin
      events_out = replicate( {stx_sim_detector_event}, nout )
      
      struct_assign, event[zout], events_out
      events_out.energy_ad_channel <= 4095
      endif else events_out = []
      
    return, events_out ;remember to make sure energy_ad_channel le 4095
end