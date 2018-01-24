;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_spc_archive2ivs
;       
; :purpose:
;       Takes a STIX L1 scp archive buffer and converts it to the ivs_interval format  
;
; :category:
;       
; :description:
;       Converts a l1_spc_combined_archive_buffer_grouped array into a stx_ivs_interval structure
;
;   
; :params:
;       ivs_str - stix ivs spc combined archive buffer structure
;       
; :keywords:
;       start_time - starting time of the archive buffer in stix time format
;          
; :returns:
;       Returns the structure img containing the counts in each interval and the start and end times and energies 
;       for the grid   
;       
; :calling sequence:
;       IDL> img = stx_spc_archive2ivs( ivs.spc_combined_archive_buffer,  start_time = ivs.start_time )
; 
;
; :history:
;       23-Sep-2014 – ECMD (Graz) 
;-

function stx_spc_l1_archive2ivs, ivs_str, start_time = start_time

;get number of intervals for reformatting to flat arrays
n = n_elements( ivs_str.counts )

;make structure of stix interval selection intervals for
img = replicate( stx_ivs_interval(), n_elements(ivs_str.counts) )

; retrieve standard full stix energy axis
energy_axis = stx_construct_energy_axis()

;get the start time of the intervals by adding the start time of the to the lower bound of the relative time range reformatted to 
; a flat array of length n
img.start_time = stx_time_add(start_time[0], seconds = reform(ivs_str.relative_time_range[0,*,*],n))

;get the end time of the intervals by adding the start time of the to the upper bound of the relative time range reformatted to 
; a flat array of length n
img.end_time = stx_time_add(start_time[0], seconds = reform(ivs_str.relative_time_range[1,*,*],n))

; get the lower energy of the intervals using the lower energy index in the input structure reformatted to 
; a flat array of length n
img.start_energy = energy_axis.low[reform(ivs_str.energy_science_channel_range[0,*,*],n)]

; get the start energy index in the input structure reformatted to a flat array of length n
img.start_energy_idx = reform(ivs_str.energy_science_channel_range[0,*,*],n)

; get the upper energy of the intervals using the higher energy index in the input structure reformatted to 
; a flat array of length n
img.end_energy = energy_axis.high[reform(ivs_str.energy_science_channel_range[1,*,*],n)] 

; get the end energy index in the input structure reformatted to a flat array of length n
img.end_energy_idx = reform(ivs_str.energy_science_channel_range[1,*,*]+1,n) 


;insert the counts for each interval into the structure
img.counts = reform(ivs_str.counts, n)

return, img
end
