;+
; :description
;    This function identifies the detector failure. A detector is in failure when it satifies two criteria :
;    1rst : the count rate in the detector is greater than the median of the count rates in the active detectors by a factor K
;    2nd : the count rate is greater than a certain minimum value (to insure statistic is good)
;    The failure should also last a certain time to require to remove a detector from the list of active detectors
;    So the procedure look if the detector was in failure (yellow flag) during at least Mbad intervals during the last Nbad quicklook intervals
;    If yes, the detector is red flagged and remove from the active detector list.
;    The function returns an updated buffer of yellow-tag words during the 16 QL intervals
;    The function also modify the parameter 'active_detectors' given as an input
;    
;    Note that there is (or there may be) a difference between 
;    the 'mask', which is the list of detector used in this function to calculate the mean and max in count rates and identify detector failure
;    the 'active_detector' list, which is the list of detectors used for decisions in the flight software, and from which we remove detectors if they are in failure 
;
; :categories:
;   STIX flight software simulator
;
; :params:
;   quicklook_accumulators : in, required, type="stx_fsw_ql_acculumator", last quicklook accumulators
;   mask : in, required, type='ULONG', list of active detectors to be take into account to run this analyse (failure detection)
;   flaretag : in, required, type='', is 0 if no flare
;   yellow : in, required, type='ULONARR(16)', list of yellow flags (words=ULONG type) over the 16 last quicklook intervals. Yellow[0] is the most recent QL interval. 
;                                              If detector number i is yellow flag, then the word will have '0' at the position i (if not, '1') 
;   active_detectors : in, required, type='ULONG', list of active detectors not used in the procedure but modified at the end if some detectors are red flagged
;   
; :keywords:
;   Kbad : in, optional, type='int', default='5', 1rst criteria, number of counts should be greater than Kbad*median
;   Rbad : in, optional, type='int', default='100', minimal number of counts for a detector to have (2nd criteria)
;   Nbad : in, optional, type='int', default='16', number of consecutive ql intervals to check where detector is yellow flagged. 
;          Should not be greater than 16 because the yellow flag list contains only the last 16 QL intervals
;   Mbad : in, optional, type='int', default='8', number of QL intervals in the Nbad intervals where the detector has to be yellow flag to become red flag
;   
; :returns:
;   yellow_to_be_return : a new version of the 'yellow' parameter 
;   'active_detectors' may be updated at the end of the function but is not returned
;
; :examples:
;   mask = 4294967295 - ULONG(2)^(31-5) - ULONG(2)^(31-7)
;   flare_tag = 0
;   yellow_flag_list = ULONARR(16)+ulong(-1)
;   active_detectors = 4294967295 - ULONG(2)^(31-5)
;   new_yellow = stx_fsw_detector_failure_identification(ql_acc, mask, flare_tag, yellow_flag_list, active_detectors)
;   new_yellow = stx_fsw_detector_failure_identification(ql_acc, mask, flare_tag, yellow_flag_list, active_detectors, Kbad=3, Rbad=1000, Nbad=10, Mbad=7)
;   
; :history:
;   26-may-2014 - Sophie Musset (LESIA), initial release
;   28-jul-2014 - Laszlo I. Etesi (FHNW), bugfix (active_detector_index_list -> active_detector_index)
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), updated trigger array to work with "only" 16 entries
;   
; :to be done:
;   26-may-2014 - Sophie Musset (LESIA) : check and modify the default and constant values
;   26-may-2014 - Sophie Musset (LESIA) : what to do with several time intervals in ql accumulators ? here always time interval 0 selected, other ignored
;-



FUNCTION stx_fsw_detector_failure_identification, ql_accumulator, lt_accumulator, mask_of_active_detector, flaretag, yellow, active_detectors, Kbad=Kbad, Rbad=Rbad, Nbad=Nbad, Mbad=Mbad, int_time=int_time, trigger_duration=trigger_duration

;-----------------------------------------
; if flare tag active, skip all procedure 
;-----------------------------------------

If (flaretag ne 0) then begin
  print, '*** flare tag is active ***'
  ;new yellow list is old yellow list
  return, yellow
Endif
 

;----------------------------
; set defaults and constants            ; ALL THESE VALUES HAVE TO BE CHECK (BY E.G. GORDON)
;----------------------------

default, Kbad, 5
default, Rbad, 100
default, Nbad, 16               ; to red flag a detector it has to be Mbad times yellow in the Nbad last QL intervals
default, Mbad, 8
Nbad <= 16              ; because yellow flag list is over the 16 last QL intervals
if Mbad gt 16 then Mbad = 8     ; idem

default, int_time,  8.                  ; integration time (for QL interval) in sec
default, trigger_duration, 0.00001     ; about 10 microseconds, to be changed

;-----------------------------------------------------------------
; calculate live_time and live time corrected detector count rates
;-----------------------------------------------------------------

quicklook_counts = fltarr(32)
quicklook_counts[*] = ql_accumulator.accumulated_counts[0,0,*,0] ; arr(1,1,32,1)
; QL Live Time is paired: but already array of 32 has been created in QL accumulators
quicklook_livetime = ulonarr(16)
quicklook_livetime[*] = lt_accumulator.accumulated_counts[0,0,*,0]
 

;Live time is just a counter (how many times it has be triggered), so need to calculate the livetime as the a time
livetime = 1. - quicklook_livetime*trigger_duration*1./int_time         ; for each detector
live_time_corrected_detector_count_rate = quicklook_counts/livetime

;--------------------------------------------------------
; test if a detector (or several detectors) behave badly
;--------------------------------------------------------

;; selection of active detectors to be taken into account in this procedure (mask)
;bin_mask = string(mask,FORMAT='(B0)')
;bin_mask_length = STRLEN(bin_mask)
;n = 32-bin_mask_length                    ; n = 0 normally, but if 0 in first position it will be greater and will not appear in the string bin_mask
;mask_of_active_detector = intarr(32)+9
;IF (n ne 0) THEN BEGIN
;  For i=0,n-1 do mask_of_active_detector[i] = 0
;  For i=n,31 do mask_of_active_detector[i] = strmid(bin_mask,i-n,1)
;ENDIF ELSE BEGIN
;  For i=0,31 do mask_of_active_detector[i] = strmid(bin_mask,i,1)
;ENDELSE

;PRINT, 'mask_of_active_detector'
;PRINT, mask
;HELP, mask_of_active_detector
;PRINT, mask_of_active_detector

; to keep track of the detector index after several selections
;todo: n.h check -1 with Sophie  
detector_index = indgen(32)

; initialisation of variables which will be updated
yellow_flag_word = bytarr(32)+1b ; yellow flag word for this QL interval, 1 everywhere (1 means no yellow flag)

;intermediate_active = where(mask_of_active_detector eq 1)

void = stx_mask2bits(mask_of_active_detector,script=intermediate_active)  

Rmed = median(live_time_corrected_detector_count_rate[intermediate_active])
Rmax = max(live_time_corrected_detector_count_rate[intermediate_active],max_index)  ; max_index is the index of the detector with the greatest countrate in the list "intermediate active"
  
If ((Rmax gt Kbad*Rmed) and (Rmax gt Rbad)) then begin 
  active_detector_index = detector_index[intermediate_active]
  ; yellow flag this detector 
  ; put a '0' for this detector in yellow flag word
  
  ;yellow_flag_word = yellow_flag_word - ULONG(2)^(31-active_detector_index[max_index])
  yellow_flag_word[intermediate_active[max_index]] = 0b       
Endif 





;add randomly errors
;rnd = randomu(systime(/seconds),4) 
;yellow_flag_word[0] = 0
;yellow_flag_word[1] = rnd[0] gt 0.2
;yellow_flag_word[2] = rnd[1] gt 0.4
;yellow_flag_word[3] = rnd[2] gt 0.6
;yellow_flag_word[4] = rnd[3] gt 0.8


;-------------------------------------------------------------
; actualistation of the yellow flag list (with time intervals)
;-------------------------------------------------------------
yellow_to_be_returned = [[yellow_flag_word], [yellow[*,0:14]]] 
;yellow_to_be_returned[*,0] = yellow_flag_word
;yellow_to_be_returned = [yellow_flag_word,yellow[0:14]] 

;-----------------------------------------------------------------------------------------------
; Look if one or several detector(s) have to be red flagged, ie remove from the active detector 
;-----------------------------------------------------------------------------------------------

; if some are yellow flag now, verification if the were yellow flag in the previous Nbad time intervals
red_flag = bytarr(32)+1b                ; initialisation to a word with '1' everywhere : no red flag

; sum all the flags for each detectors from last QL to the Nbad eme QL
; if no yellow flag, sum_yellow = Nbad... Red flag detectors if sum_yellow < Nbad-Mbad



;Load a word in a rotating buffer that indicates which detector(s) if any, were yellow flagged.
;If this detector was yellow-flagged in the previous Nbad intervals as well, then the detector is ‘red-flagged’. 

sum_yellow = total(~yellow_to_be_returned[*,0:Nbad-1],2)
red = where(sum_yellow ge mbad AND yellow_flag_word eq 0, n_red)
IF n_red gt 0 then begin
  ;stop
  red_flag[red] = 0
endif

;-------------------------------------------------------------
; actualisation of the active_detectors
;-------------------------------------------------------------
active_detectors = (active_detectors AND red_flag)

return, yellow_to_be_returned

END  