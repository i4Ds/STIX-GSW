;---------------------------------------------------------------------------
;+
; project:
;       STIX
;
; :name:
;       stx_l1_spc_ivs2spectrogram
;       
; :purpose:
;       Takes a STIX interval selection output structure and converts it into a regular spectrogram ;    
;
; :category:
;       
;       
; :description:
;      Converts a l1_spc_combined_archive_buffer_grouped array from the interval 
;      selection algorithm into a regularly gridded spectrogram
;  
; :params:
;       ivs - stx_fsw_ivs_result structure
;       
; :keywords:
;       none
;                 
; :returns:
;       Returns the structure spect_struct containing the regular grid spectrogram 
;       
; :calling sequence:
;       IDL> spectrogram = stx_l1_spc_ivs2spectrogram( ivs )
;       
; :history:
;       06-Oct-2014 – ECMD (Graz), initial release
;       12-Dec-2014 – ECMD (Graz), fixed dimensions to agree with new standard index order of count(energy, pixel, detector, time)
;                                  livetime array of 32 detector x n time intervals now created and multiplied by
;                                  detector mask before calculation of fractional livetime 
;       
;-
function stx_l1_spc_ivs2spectrogram, ivs
 
;get the level 1 spectrometry interval archive
l1 = ivs.l1_spc_combined_archive_buffer_grouped.toarray()
 
;get the counts for each interval
data = l1.intervals.counts

;get the indices for the energy channels
e_edges = get_uniq( [ (l1.intervals.energy_science_channel_range)[0,*,*] , $
         (l1.intervals.energy_science_channel_range)[1,*,*]  ] )
         
;get the edges for the time bins from the relative time range for each interval 
;and the first element of the start time array         
t_edges = stx_time_add( (l1.start_time)[0] , $
          seconds = [ get_uniq(l1.intervals.relative_time_range) ] )

;construct an energy and time axis structures using the edges
e_axis = stx_construct_energy_axis(select = e_edges)
t_axis = stx_construct_time_axis(t_edges)

; l1.livetime no longer part of structure maybe it never was SM 17-01-17

;get the original dimensions of the counts array
dim = size( l1.intervals.counts, /dim)
;pdim = product(dim)

;create 1D array with the total number of elements as the count array
;ltime_det = fltarr(32*dim[1])
;;get the odd and even indices
;shift1 = 2*findgen(16*dim[1])
;shift2 = shift1+1
;
;;insert the archive buffer livetime into both the odd and even indices
;ltime_det[shift1] = l1.livetime
;ltime_det[shift2] = l1.livetime
;
;;reform to have same dimensions as detector mask [32 detectors x n time intervals]
;ltime_det = reform(ltime_det, 32, dim[1])
;
;;get the detector mask for the intervals
;det_mask = l1.detector_mask
;
;;apply the detector mask 
;ltime_det = ltime_det*det_mask
;
;;get the total number of triggers for each time interval
;ltime_interval = total(ltime_det,1)/2.
;
;;divide the triggers by the counts in each time interval to get the fractional livetime
;frac_ltime_interval=total(data,1)/ltime_interval
;
;;replicate the 1D array of the fractional livetime for each interval for each energy channel
;ltime = transpose(rebin(frac_ltime_interval,dim[1],dim[0]))
ltime=fltarr(dim)

;create a stix spectrogram structure and insert the parameters from the archive buffer 
spect = stx_spectrogram(data, t_axis, e_axis, ltime, attenuator_state = l1.rcr)

return, spect
end
