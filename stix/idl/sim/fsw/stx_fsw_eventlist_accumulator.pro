
;+
;
; :Name:
;   stx_fsw_eventlist_accumulator
; :description:
;   This function is a general constructor of stix spectrograms for use 
;   in the flight software simulation.
;
; :categories:
;    flight software, constructor, simulation
; :Params:
;   Eventlist : structure containing energy or trigger events to accumulate
;     Structure must contain either calibrated, uncalibrated energy events, or trigger events
;
; :keywords:
;   channel_bin - integer bin edges for energy accumulation as a 1 d vector form, must be contiguous bins
;     can be for the science channels or a2d channels, same for all detectors and pixels
;     defaults to [1,4, 9, 15, 31]
;     The standard energy bin edges are from 0-32 corresponding to science event channels from 0-31. 
;     e.g. the specification for the lightcurve channel bin, "0-3-7-12-20-32"
;     gives these energy bins:
;     0-2 inclusive
;     3-6 inclusive
;     7-11 inclusive
;     12-19 inclusive
;     20-31 inclusive
;   interval_start_time - stx_time, starting time for accumulation interval 
;   det_index_list - integer type, vector with values from 1-32, list of all detectors to include in accumulation, defaults to indgen(32)+1
;   pixel_index_list - integer type, vector with values from 1-12, list of all pixels to include in accumulation, defaults to indgen(12)+1
;   pixel_sub_sum - integer type, if set then it does the special corner sum of the pixels, 0:1, 2:3, 4:5, 6:7
;   dt - fixed time bin size, defaults to 4 seconds.  
;   time_bin - time bin edges in stx_time (or anytim ) readable format.
;   accumulator - type of output structure, string, default 'lightcurve', ql_accumulator_prefix is prepended in the output structure
;   no_prefix - if no_prefix is set then don't prepend 'stx_fsw_ql_'
;   sum_det - default is 1, if set sum accumulation over detectors 
;   sum_pix - default is 1, if set sum accumulation over pixels (default for triggers)
;   a2d_only - only used for triggers for a2d LT accumulation, default is 0, set to 1 to return a2d only in a2d order
;     if set, then all 16 a2d are returned
;   livetime - 0 or 1, if set then the accumulator type is LT and events are TRIGGER_EVENTS
;   active_detectors -   default, active_detectors, bytarr(32) + 1b, 1 active, 0 inactive
;     use EXCLUDE_BAD_DETECTORS to condition output
;   
;
;   exclude_bad_detectors - default, exclude_bad_detectors, 1b
;;   error - returns a 1 if an error in the input prevents the completion
;
                 
; :returns:
;    a stx_sim_archive_buffer structure
;
; :examples:
;    science_channels = stx_fsw_get_science_channels()
;    ;filtered_eventlist comes from the event simulation (see stx_ds_demo )
;    calib_eventlist = stx_fsw_science_energy_application( sd.filtered_eventlist, science_channels )
;    help, calib_eventlist,/st
;    ** Structure <bc49170>, 4 tags, length=6005304, data length=4128678, refs=1:
;     TYPE            STRING    'stx_sim_calibrated_detector_eventlist'
;     START_TIME      STRUCT    -> <Anonymous> Array[1]
;     SOURCES         STRUCT    -> <Anonymous> Array[1]
;     DETECTOR_EVENTS STRUCT    -> STX_SIM_CALIBRATED_DETECTOR_EVENT Array[375322]
;     
;     To accumulate all 16 livetime a2d
;  IDL> out =stx_fsw_eventlist_accumulator( triggers, /livetime, /a2d_only, accumulator='stx_lt_accumulator', /no_prefix, sum_det=0)
;  IDL> help, out,/st
;  ** Structure <c065890>, 3 tags, length=4352, data length=4352, refs=1:
;     TYPE            STRING    'stx_lt_accumulator'
;     TIME_AXIS       STRUCT    -> <Anonymous> Array[1]
;     ACCUMULATED_COUNTS
;                     FLOAT     Array[1, 1, 16, 30]
;  IDL> out =stx_fsw_eventlist_accumulator( triggers, /livetime, /a2d_only, accumulator='stx_lt_accumulator', /no_prefix, sum_det=0, dt=2)
;  IDL> help, out,/st
;  ** Structure <c065c90>, 3 tags, length=8672, data length=8672, refs=1:
;     TYPE            STRING    'stx_lt_accumulator'
;     TIME_AXIS       STRUCT    -> <Anonymous> Array[1]
;     ACCUMULATED_COUNTS
;                     FLOAT     Array[1, 1, 16, 60];
;  
;  To generate a list of accumulators for each time bin, (channel, pixel, detector, time) use these arguments
;  out = stx_fsw_eventlist_accumulator( calib_det_eventlist,  channel_bin= indgen(33), sum_pix=0, sum_det=0, time_bin= time_bin)
;  IDL> help, out
;  ** Structure <2b6ac900>, 4 tags, length=50312, data length=50308, refs=1:
;     TYPE            STRING    'stx_fsw_ql_lightcurve'
;     TIME_AXIS       STRUCT    -> <Anonymous> Array[1]
;     ENERGY_AXIS     STRUCT    -> <Anonymous> Array[1]
;     ACCUMULATED_COUNTS
;                     LONG      Array[32, 12, 32, 1];
;
;    spectrogram_struct = $
;    stx_fsw_eventlist_accumulator( calib_eventlist, $
;
;           channel_bin = channel_bin, $
;           interval_start_time = interval_start_time, $
;           det_index_list = det_index_list, $
;           pixel_index_list = pixel_index_list, $
;           pixel_sub_sum = pixel_sub_sum, $
;           time_bin = time_bin, $
;           dt = dt , $
;           no_prefix = no_prefix,  $
;           accumulator = accumulator, $
;           a2d_only = a2d_only, $
;           sum_det = sum_det, $ 
;           sum_pix = sum_Pix, $
;           livetime= livetime, $
;           active_detectors = active_detectors, $
;           exclude_bad_detectors = exclude_bad_detectors, $
;           error = error )
;
; :history:
;     28-mar-2014, richard.schwartz@nasa.gov
;     22-apr-2014, richard.schwartz@nasa.gov, initial working version
;     26-apr-2014, richard.schwartz@nasa.gov, added pixel_sub_sum to support corner pixel sum, added 
;     energy axis
;     07-may-2014, Laszlo I. Etesi (FHNW), replaced last lime (construction of ql accumulator) with construction function
;     7-may-2014, richard.schwartz@nasa.gov, for case of nvalid of 0 create lonarr with correct dimensions
;     8-may-2014, richard.schwartz@nasa.gov, "Corners" sum reformulated in a more transparent way.
;     21-may-2014, richard.schwartz@nasa.gov, remove confusion about major_frames
;       now data are strictly binned by  nchan_bin, npix_bin, ndet_bin, ntime_bin where then number of
;       bins is always 1 or more.  The number of time bins depends on the number of time intervals based on 
;       dt, the accumulator time interval, and includes the last fractional time bin. 
;     18-june-2014, ECMD (GRAZ), additional documentation and moved reform of spectrogram to outside test for valid data. 
;     31-july-2014, richard.schwartz@nasa.gov, added interval_start_time and removed start_time, events are accumulated
;     on dt length bins starting from interval_start_time 
;     09-sep-2014, nicky hochmuth (FHNW), 
;       bugfix for det_index_list is passed in but is not a pointer
;       bugfix for LT case pixel_sub_sum is set to 0 as default
;     10-sep-2014, richard.schwartz@nasa.gov
;       bugfix for channel_bin passed as array and not a pointer, same as fix for det_index_list
;       added documentation on how to look at the full accumulation registers. 
;     11-sep-2014, richard.schwartz@nasa.gov, spectrogram count array in structure is ulong
;     19-nov-2014, richard.schwartz@nasa.gov, included new keywords, active_detectors and
;     exclude_bad_detectors, fixed first implementation which was crazy
;     18-dec-2014, richard.schwartz@nasa.gov, extend active_detectors mask exclusion to
;     trigger as well as energy events
;     3-aug-2015, richard.schwartz@nasa.gov, 
;       ;Must check one pixel_index_list in an if statement, fixed ras, 3-aug-2015, line 214-215
;       ;Interval start time is ut_start by definition, RAS, 3-aug-2015, line 303-305
;       ;pixel_index_list has to exist  as something before using brackets on it, ras, 4-aug-2015
;     16-aug-2015, richard.schwartz@nasa.gov
;       internally active_detectors changed to active_detectors_use since this can now be changed
;       according to the det_index_list. So now to be included a detector must be on the det_index_list
;       and not excluded by the active_detectors mask
;     26-feb-2016 - ECMD (Graz), removed adjustment of channel bin edges to catch the last edge,
;        slightly clearer documentation on how channel bin edges are handled
;     10-may-2016 - Laszlo I. Etesi (FHNW), minor updates to accommodate structure changes
;     22-jan-2017 - richard.schwartz@nasa.gov, take defaults for ql energy channel edges from 
;     science_energy_channel database spreadsheet
;      :todo:
;   needs work on output data structure and more documentation on trigger eventlist
;-
function stx_fsw_eventlist_accumulator, eventlist, $

           channel_bin = channel_bin, $
           interval_start_time = interval_start_time, $
           det_index_list = det_index_list, $
           pixel_index_list = pixel_index_list, $
           pixel_sub_sum = pixel_sub_sum, $
           time_bin = time_bin, $
           dt = dt, $
           a2d_only = a2d_only, $ ;ras, added 10-sep-2014
           accumulator = accumulator, $
           no_prefix = no_prefix, $ ;ras, added 10-sep-2014
           sum_det = sum_det, $ (or 0)  
           sum_pix = sum_pix, $
           livetime = livetime, $
           active_detectors = active_detectors, $
           exclude_bad_detectors = exclude_bad_detectors, $
           error   = error

if accumulator eq 'bkgd_monitor_lt' then begin
  print, "bkgd_monitor_lt"
endif
           
error = 1
;Determine if input structure contains a single eventlist structures and extract the relevant variables if so
if n_elements( eventlist ) eq 1 then begin
  tags = tag_names( eventlist )
  idx_events = where( stregex( tags, /boolean, /fold, 'event'))
  events = eventlist.(idx_events)
  start_time = eventlist.time_axis.time_start
  endif else events = eventlist
nevents = n_elements( events )
;Detector events or trigger events
struct_name = tag_names( events, /struct )
is_energy_event = ~stregex( struct_name, /boolean, /fold, 'trigger')
;set the default values if corresponding keyword inputs are not present
;the defaults match the expected inputs of the lightcurve accumulator
default, dt, 4.0 ;default time interval in seconds
;channel bins but be contiguous whether in ad  or energy space
;default, channel_bin, [1,4, 9, 15, 31] ;4 quasi arbitrary channel ranges
if ~keyword_set( channel_bin ) then begin ;defaults for ql channels from dbase
  qlc=(stx_science_energy_channels(/str)).ql_channel
;  IDL> print, qlc
;  0       0       0       0       0       0       1       1       1       1       1       2       2       2       2       2       3       3       3       3
;  3       3       4       4       4       4       4       4       4       4       4       4      -1
;  IDL> print, where( qlc[1:*] ne qlc)
;  5          10          15          21          31
  channel_bin = [0, where( qlc[1:*] ne qlc)+1]
;  IDL> print,[0, where( qlc[1:*] ne qlc)+1]
;  0           6          11          16          22          32

endif
if ptr_valid( channel_bin[0] ) then channel_bin = *channel_bin 

default, exclude_bad_detectors, 1b
default, det_index_list, indgen(32) + 1 ;ras, this has to come first, 10-sep-2014
if ptr_valid( det_index_list[0] ) then det_index_list = *det_index_list
default, active_detectors, bytarr(32) + 1b
active_detectors_use = byte( ( active_detectors < 1b ) > 0b )
mask = bytarr(32) & mask[ det_index_list-1 ] = 1
active_detectors_use *= mask 
;default, major_frame_time, 32.0 ;unused, ras, 21-may-2014
default, sum_det, 1
default, sum_pix, 1
default, accumulator, 'lightcurve'
default, livetime, 0
default, pixel_sub_sum, 0
default, no_prefix, 0
default, ql_accumulator_prefix, 'stx_fsw_ql_' ;ras, added, 10-sep-2014
if no_prefix then ql_accumulator_prefix = ''
default, a2d_only, 0 
  
ql_accumulator = ql_accumulator_prefix + accumulator

default, interval_start_time, start_time ;if you haven't passed anything else
;if not summed then chosen det_index are reported individually but all are put
;into the initial spectrogram
;ensure that livetime keyword is set if input is trigger eventlist
;ptim, start_time.value
is_trigger_event = ~is_energy_event
if is_trigger_event and ~livetime then begin
  message,'Trigger events must be used with LIVETIME keyword set'
  return, -1
  endif
case 1 of 
is_energy_event: begin
  ; Determines the indices to be used in creating the spectrogram for pixel, detector and energy channels based on 
  ; the input bin lists - elements corresponding to indices which are not to be included in the accumulated spectrogram 
  ; are set to -1
  ;Must check one pixel_index_list in an if statement, fixed ras, 3-aug-2015, pixel_index_list has to exist
  ;as something before using brackets on it, ras, 4-aug-2015
  default, pixel_index_list, indgen(12) 
  if ptr_valid( pixel_index_list[0] ) then pixel_index_list = *pixel_index_list 
  pixel_index_list = pixel_sub_sum ? indgen(8) : pixel_index_list
  pixel_sum = pixel_sub_sum ? 0 : pixel_sum ;special summation of corners if pixel_sub_sum set
  pix_target = intarr(12) - 1
  npix_bins = n_elements( pixel_index_list )
  ix_target = indgen( npix_bins )
  pix_target[ pixel_index_list ] = ix_target
  pix_ix = pix_target[ events.pixel_index ]
  
  det_target=intarr(33)-1
  ndet_bins = n_elements( det_index_list )
  ix_target = indgen( ndet_bins )
  det_target[det_index_list] = ix_target
  det_or_ad_ix = det_target[ events.detector_index ]
  
  channel_bin_use = get_edges(channel_bin, /edges_1) 
  num_chan = n_elements( channel_bin_use ) - 1
  ;for energies value_locate is used to determine which event energy channels fall into 
  ;each accumulator energy channel bins
  eg_index =  value_locate( channel_bin_use, events.energy_science_channel ) 
  
  end
  is_trigger_event: begin 
  
  ;
  ;get det isc for ad_group
  det_ad_match = stx_ltpair_assignment( indgen(32) + 1, /adgroup_idx )
  pix_ix = intarr( nevents )
  npix_bins = 1
  num_chan = 1
  
  ndet_bins = 16
  ndets = n_elements( det_index_list ) ;to dimension the final spectrogram
  det_or_ad_ix = events.adgroup_index - 1
  eg_index = lonarr(nevents)
  end
  endcase
; Set eg_index for inactive detectors to -1 based on the active_detectors_use mask
;Inactive detectors mask block
;;   Precondition
;    the detector health module updates frequently a mask with all active detectors:
;    active_detectors_use: byte array with 32 entries, positional indexed, 1 detector is active, 0 otherwise
;    in the event list at every time all detector events occur. The data simulation does not filter anything
;    goal
;    
;    hide/disable all events for bad detectors in the ql-accumulation
;    it might by that the filtering of events from bad detectors should not be applyed to every ql_accumulator.
;    Therefor an addtional parameter in the ql_accumulator definition file is needed (exclude_bad_detectors : 0|1)
;    use cases
;    
;    lets assume we only have a total number of 5 detectors the following use cases are describing different accumulator definitions (set in qlook_accumulators_clocked.csv):
;    this examples only focus the detector counts (there is still the time, energy and pixel dimension)
;    active_detectors_use = [1, 0, 0, 1, 1]
;    counts_per_detector from event_list: [10, 20, 30, 40, 50]
;    exclude_bad_detectors : 0 and sum_det : 1
;    same output as right now
;    accumulated_counts = 150
;    exclude_bad_detectors : 0 and sum_det : 0
;    same output as right now
;    accumulated_counts =  [10, 20, 30, 40, 50]
;    exclude_bad_detectors : 1 and sum_det : 1
;    accumulated_counts = 110
;    exclude_bad_detectors : 1 and sum_det : 0
;    accumulated_counts = [10, 0, 0, 40, 50] or [10, NAN, NAN, 40, 50] TBD
;    implemented by
;    if sum_det && exclude_bad_detectors then $
;     eg_index = active_detectors_use[ eg_index ] ? eg_index : -1
;     Negative values of eg_index are not included in any output detector counts
  ;all three conditions must hold to take this action, 
  ;last condition looks for any inactive detectors with a mask value of 0
if exclude_bad_detectors && ~min( active_detectors_use ) then begin
  ;set inactive det counts out of range
  ;Do this for count events and triggers, the active_detectors_use mask is conditioned correctly
  ;by the caller!
   inactive = where( ~active_detectors_use[ events.detector_index - 1 ], n_inactive )
   if n_inactive ge 1 then eg_index[ inactive ] = -1
   endif
; index the time interval of each event based on the input time bins
; if no time bins are passed set the time bins based on the duration of the accumulator, dt,  
; ensuring all events are included 
ut_start = stx_time2any( interval_start_time )
;time_mm = minmax( events.relative_time )  + stx_time2any( eventlist.start_time )
;Interval start time is ut_start by definition, RAS, 3-aug-2015
time_mm = [ut_start, max( events.relative_time )  + stx_time2any( eventlist.time_axis.time_start )]
num_tm = ceil( ( time_mm[1] - time_mm[0] )/ dt ) 
num_tm = (num_tm + 1 ) > 2
default, time_bin, ut_start + dindgen( num_tm ) * dt
time_bin_use = stx_time2any( time_bin )
time_bin_use = get_edges( time_bin_use, /edges_1 )
num_tm = n_elements( time_bin_use ) -1
;tm_index = value_locate(time_bin_use - ut_start, events.relative_time )
;todo: N.H. check with resrichard
tm_index = value_locate(time_bin_use - ut_start+stx_time_diff(interval_start_time,eventlist.time_axis.time_start), events.relative_time )
;generate full index array used to build spectrogram array with histogram - each value corresponds to a 
;given combination of energy, pixel, detector and time indices
total_index_for_hist = eg_index + pix_ix * num_chan + det_or_ad_ix * ( num_chan * npix_bins )  + $
  tm_index * ( num_chan * npix_bins * ndet_bins )
max_bin = num_chan * npix_bins * ndet_bins * num_tm -1 
;indices are considered valid if they have not been set to -1 (for detector and pixel indices)
;or are within the range of bins given to value_loacate (for energy and time indices)
valid = where( (det_or_ad_ix ge 0 ) and (pix_ix ge 0) and $
  (eg_index ge 0 and (eg_index le (num_chan - 1)))  and $
  (tm_index ge 0 and (tm_index le (num_tm -1))), nvalid)
if nvalid ge 1 then begin
  spectrogram = histogram( min= 0, max = max_bin, total_index_for_hist[valid] )
  endif else spectrogram = lonarr( num_chan, npix_bins, ndet_bins, num_tm )
  ;alter dimensions of spectrogram to 4D array  of [nchan_bin, npix_bin, ndet_bin, ntime_bin] 
  spectrogram = reform( /over, spectrogram, num_chan, npix_bins, ndet_bins, num_tm )
;return, spec_struct
if is_trigger_event then begin
  if ~a2d_only then begin
    ndet_bins = n_elements( det_index_list )
    spec_out = lonarr( 1, 1, ndets, num_tm )
    for ii = 0, ndet_bins -1 do begin
      spec_out[0, 0, ii, * ]  = spectrogram[ 0, 0, det_ad_match[ii]-1, * ] 
      endfor
    spectrogram = spec_out
    endif else ndet_bins = 16
  ;These are trigger events and they are most useful
  endif
if sum_det then begin
    ;TODO n.h: check with richard if correct for binsize of max 4 seconds 
    if (size(spectrogram))[0] gt 2 then spectrogram = total( spectrogram, 3, /preserve_type)
  ndet_bins = 1
  endif
;The next line just reshapes the spectrogram, unnecessary but it helps the logic
spectrogram = reform( spectrogram, /over , num_chan, npix_bins, ndet_bins, num_tm )
if sum_pix then begin
  spectrogram = total( spectrogram, 2, /preserve_type )
  npix_bins = 1
  endif
;keep the shape with 4 dimensions
spectrogram = reform( spectrogram, /over , num_chan, npix_bins, ndet_bins, num_tm )
if pixel_sub_sum then begin
;This  is the CORNERS sum for the imaging detectors. Reformulated 8-may-2014 after an issue found by Ewan Dickson
  npix_bins = 4
  spec_out  = lonarr( num_chan, npix_bins, ndet_bins, num_tm)
  for ii = 0, 7, 2 do spec_out[*, ii/2, *, *] = total( spectrogram[*, ii:ii+1, *, *], 2)
  spectrogram = spec_out
  endif

;;does time interval divide evenly major frame time, if so, group the times 
;if ( num_tm * dt ) mod major_frame_time eq 0 then begin
;  nframes = num_tm * dt / major_frame_time
;  nsubframes = major_frame_time / dt
;  spectrogram = reform( spectrogram, /over, num_chan, npix_bins, ndet_bins, nsubframes, nframes )
;  endif
;  
error = 0 ;successful completion
detector_mask = stx_mask2bits(active_detectors_use)

 if livetime then begin
    
 endif else begin
    pixel_mask = bytarr(12)
    pixel_mask[pixel_index_list] = 1b
    pixel_mask = stx_mask2bits(pixel_mask)
 endelse
 
ql_str = stx_construct_fsw_ql_accumulator(ql_accumulator, time_bin, ulong( spectrogram ), channel_bin_use=channel_bin_use, is_trigger_event=is_trigger_event, detector_mask=detector_mask, pixel_mask=pixel_mask)
;if ql_accumulator eq 'stx_fsw_ql_lightcurve' then begin
;  help, ql_str
;  print, total(spectrogram), n_elements(eventlist.detector_events)
;  pmm, eventlist.detector_events.relative_time
;  ptim, interval_start_time.value, eventlist.start_time.value
;end
return, ql_str
end


