
openr, lun, 'C:\Users\LaszloIstvan\Dropbox (STIX)\FSW_Test_Data\Data\Published\20170124_221151\ESC\20170309\T6a\T6a_rb_processing.txt' , /GET_LUN
; Read one line at a time, saving the result into array
lines = list()
line = ''
first = 1
while not eof(lun) do begin
  readf, lun, line
  lines->add, line
endwhile
; Close the file and free the file unit
free_lun, lun

lines->remove, 0

stx_telemetry_util_time2scet,coarse_time=0, fine_time=0, stx_time_obj=ref_time, /reverse
start_time = ref_time

all_entries = list()

foreach line, lines do begin
  check_duplicates = hash()
  time = STRMID(line, 12, 15)
  hex2dec,STRMID(time,2,8), ctime, /quiet
  hex2dec,STRMID(time,11), ftime, /quiet
    
  data =  STRSPLIT(STRMID(line, 28), " ", /EXTRACT)
  
  data = data[0:-17]
  
  entries = replicate({stx_fsw_archive_buffer}, n_elements(data))
  entries.RELATIVE_TIME_RANGE[0,*] = stx_time_diff(start_time, ref_time, /abs) 
  
  stx_telemetry_util_time2scet,coarse_time=ctime, fine_time=ftime, stx_time_obj=end_time, /reverse
  
  entries.RELATIVE_TIME_RANGE[1,*] = entries.RELATIVE_TIME_RANGE[0,*] + stx_time_diff(start_time, end_time, /abs) 
  
  start_time = end_time
  
  entries.COUNTS = 1
  
  print, time
  print, entries[0].RELATIVE_TIME_RANGE
  
  openw, lun, 'c:\temp\list.txt', /get_lun
  foreach entry_str, data, idx do begin   
    ;if idx gt (n_elements(data) then break
    HEX2BIN, entry_str, entry, /quiet
;    if entry_str eq '0x621A03B1' then begin
;      print, '0x621A03B1'
;    endif
    entry = entry[-4*(strlen(entry_str)-2):*]
    
    addr = stx_mask2bits(reverse(entry[0:13]))
    if(check_duplicates->haskey(addr)) then check_duplicates[addr] = check_duplicates[addr] + 1 $
    else check_duplicates[addr] = 1
      
    entries[idx].pixel_index = byte(stx_mask2bits(reverse(entry[0:3])))
    entries[idx].detector_index = byte(stx_mask2bits(reverse(entry[4:8])))
    entries[idx].ENERGY_SCIENCE_CHANNEL = byte(stx_mask2bits(reverse(entry[9:13])))
    cont = byte(stx_mask2bits(reverse(entry[14:15])))
    
    printf, lun, entries[idx].pixel_index, entries[idx].detector_index, entries[idx].ENERGY_SCIENCE_CHANNEL, cont, entry_str
    
    ;triggers
;    print, cont, n_elements(entry)
;    if (cont gt 2) OR (cont eq 1 AND (n_elements(entry) gt 24)) then begin
;      print, "triggers at position ", idx, " from ", n_elements(data) 
;      break
;    endif
       
    if cont eq 0 then continue else entries[idx].counts = ulong(stx_mask2bits(reverse(entry[16:*])))
  endforeach
  free_lun, lun
  foreach addr_entry, check_duplicates->keys() do begin
    if(check_duplicates[addr_entry] gt 1) then print, addr_entry, check_duplicates[addr_entry]
  endforeach
  stop
  all_entries->add, entries, /extract
endforeach
  
 all_entries = all_entries->toarray()
 
 all_fsw_entries=list()
 
 restore, filename='C:\Users\LaszloIstvan\Dropbox (STIX)\FSW_Test_Data\Data\Raw\v20170124\T1a\T1a_dss-fsw.sav', /ver, /relaxed_structure_assignment
 fsw->getproperty,stx_fsw_m_archive_buffer_group = abg, /complete 
 
 foreach fsw_g, abg do begin
  all_fsw_entries->add, fsw_g.ARCHIVE_BUFFER, /extract
 endforeach
 
 all_fsw_entries = all_fsw_entries->toarray()
 
 ;correct the det labeling
 all_entries.detector_index++
 
 all_entries_cor = all_entries
 
 detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30]
 detector_mapping_new = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30]
 
 idx = where(all_entries.detector_index eq detector_mapping_new)
 
 for i=1, 32 do begin
  det_i = where(all_fsw_entries.detector_index eq i) 
  all_entries_cor[det_i].detector_index = replicate(byte(detector_mapping_new[where(detector_mapping_old eq i)]), n_elements(det_i))
 endfor

 all_entries_backup = all_fsw_entries
 all_fsw_entries = all_entries_cor

 esc_cs = stx_fsw_compact_archive_buffer(all_entries, total_counts=esc_total_counts, time_axis=time_axis, start_time=stx_construct_time())
 fsw_cs = stx_fsw_compact_archive_buffer(all_fsw_entries, total_counts=fsw_total_counts)
 energy_axis = stx_energy_axis()
 
 used_energies_fsw = all_fsw_entries[UNIQ(all_fsw_entries.ENERGY_SCIENCE_CHANNEL, SORT(all_fsw_entries.ENERGY_SCIENCE_CHANNEL))].ENERGY_SCIENCE_CHANNEL 
 used_energies_esc = all_entries[uniq(all_entries.ENERGY_SCIENCE_CHANNEL, sort(all_entries.ENERGY_SCIENCE_CHANNEL))].ENERGY_SCIENCE_CHANNEL
 
 fsw_spg = stx_fsw_ivs_spectrogram(fsw_total_counts,time_axis) 
 esc_spg = stx_fsw_ivs_spectrogram(esc_total_counts,time_axis) 
 dif_abs_spg = stx_fsw_ivs_spectrogram(abs(fsw_total_counts-esc_total_counts),time_axis) 
 dif_spg = stx_fsw_ivs_spectrogram((fsw_total_counts-esc_total_counts),time_axis) 
 dif2_spg = stx_fsw_ivs_spectrogram((esc_total_counts-fsw_total_counts),time_axis) 
  
 stx_interval_plot, esc_spg, title="ESC ArchiveBuffer", skipcontour=1
 stx_interval_plot, fsw_spg, title="FSW ArchiveBuffer", skipcontour=1
 stx_interval_plot, dif_abs_spg, title="abs(FSW-ESC) ArchiveBuffer", skipcontour=1
 stx_interval_plot, dif_spg, title="ulong(FSW-ESC) ArchiveBuffer", skipcontour=1
 stx_interval_plot, dif2_spg, title="ulong(ESC-FSW) ArchiveBuffer", skipcontour=1
 
 window, /free, title="Total Spectrum"
 plot, total(esc_spg.counts,2)
 oplot, total(fsw_spg.counts,2),thick=2
 
 help, all_entries
 help, all_fsw_entries
 
 print, total(all_entries.counts, /pre)
 print, total(all_fsw_entries.counts, /pre)
   
 stop
 
 matches = all_fsw_entries
 
 ;ind = string(fix(all_entries.detector_index))+string(fix(all_entries.pixel_index))+string(fix(all_entries.energy_science_channel))
 
 ;print, ind
 
 ;ind_fsw = string(all_fsw_entries.relative_time_range[0,*]) + string(all_fsw_entries.relative_time_range[1,*]) + string(fix(all_fsw_entries.detector_index))+string(fix(all_fsw_entries.pixel_index))+string(fix(all_fsw_entries.energy_science_channel))

 
 forremoving = list()
 
 foreach esc_entry, all_entries, countIDX do begin
   matchIDX = where( $
     matches.relative_time_range[0] eq esc_entry.relative_time_range[0] $
     and matches.relative_time_range[1] eq esc_entry.relative_time_range[1] $
     and matches.detector_index eq esc_entry.detector_index $
     and matches.pixel_index eq esc_entry.pixel_index $
     and matches.energy_science_channel eq esc_entry.energy_science_channel, hasMatch)

   if hasMatch eq 0 then begin
     print, "no BIN Match", countIDX
     continue
   endif

   if hasMatch eq 1 then begin

     candidate = matches[matchIDX]
     if candidate.counts eq esc_entry.counts then begin
       forremoving->add, matchIDX
       continue
     endif else begin
       print, "no COUNT Match", countIDX, candidate.counts, esc_entry.counts
       continue
     endelse

   endif


   if hasMatch gt 1 then begin
     print, "to many BIN Matches", countIDX
     continue
   endif
   
 endforeach
 
 remove, forremoving->toarray(), matches
 
 stop  
end

