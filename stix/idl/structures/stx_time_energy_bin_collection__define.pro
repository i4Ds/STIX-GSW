;+
; PROJECT:          STIX
;
; NAME:             stx_time_energy_bin_collection Object
;
; PURPOSE:          providing a querying interface to a set of stx_time_energy_bin 
;
; CATEGORY:         structures
;
; CALLING SEQUENCE: 
;                    a = stx_time_energy_bin(1,2,4,5,"a")
;                    b = stx_time_energy_bin(2,4,6,10,"b")
;                    c = stx_time_energy_bin(3,5,8,20,"c")
;                    col = stx_time_energy_bin_collection([a,b,c])
;                    found = col->select(time=[2.1,4],count_matches=count_matches)
;
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-

;+
; :description:
;   This function creates a stx_time_energy_bin_collection a data container for a set of stx_time_energy_bins
;
; :params:
;    bins   : type="array(stx_time_energy_bin)"
;             a scalar or array of stx_time_energy_bins
; :returns:
;    [0|1] on succes
;
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-
function stx_time_energy_bin_collection::init, bins

   self->add, bins
   return, 1
end

;+
; :description:
;   adds stx_time_energy_bins to the collection
;
; :params:
;    bins   : type="array(stx_time_energy_bin)"
;             a scalar or array of stx_time_energy_bins
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-
pro stx_time_energy_bin_collection::add, bins
  n_bins = n_elements(bins) 
  if n_bins gt 0 then begin
      bin_interfaces = replicate(stx_time_energy_bin(),n_bins)
      for i=0L, n_bins-1 do bin_interfaces[i]=stx_time_energy_bin(bins[i])
      if ~ptr_valid(self.bins) then begin
        self.bins = ptr_new(bin_interfaces)
      endif else begin
        *(self.bins) = [*(self.bins) , bin_interfaces]
      endelse
  endif
end

;+
; :description:
;   returns a bounding box defined by all members of the collection
;   
; :keywords:
;   energy : in, type="[0|1]", default 1
;            add energy dimension to the bounding box
;   time   : in, type="[0|1]", default 1
;            add time dimension to the bounding box
; :returns:
;    {  energy: [min,max], time  : [min,max] } if time and energy as active
;    [min,max] if only one dimension is activated
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-
function stx_time_energy_bin_collection::get_boundingbox, energy=energy, time=time
 
  if ~keyword_set(energy) || keyword_set(time) then begin
    void = min((*self.bins).time_start,start_time_idx)
    void = max((*self.bins).time_end,end_time_idx)
    time_boundary = [ (*((*self.bins).data)[start_time_idx]).time_range[0] , (*((*self.bins).data)[end_time_idx]).time_range[1]]
  end
  
  if keyword_set(time) && ~keyword_set(energy) then return, time_boundary
  
  start_energy = min((*self.bins).energy_start)
  end_energy = max((*self.bins).energy_end)
  
  energy_boundary = [start_energy,end_energy]
  
  if keyword_set(energy) && ~keyword_set(time) then return, energy_boundary
  
  return, {energy:energy_boundary,time:time_boundary}
end

;+
; :description:
;   creating time|energy axes defined by all members of the collection
;   
; :keywords:
;   energy : in, type="[0|1]", default 1
;            add energy axes to the output
;   time   : in, type="[0|1]", default 1
;            add time axes to the output
; :returns:
;    {  energy: stx_energy_axis, time  : stx_time_axis } if time and energy as active
;    stx_?_axes if only one dimension is activated
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-
function stx_time_energy_bin_collection::get_axis, energy=energy, time=time
  if ~keyword_set(energy) || keyword_set(time) then begin
    time_eges = [(*self.bins).time_start, (*self.bins).time_end]
    time_eges = time_eges[sort(time_eges)]
    time_eges = time_eges[uniq(time_eges)]
    
    time_axis = stx_time_axis(time_eges)
  end
  
  if keyword_set(time) && ~keyword_set(energy) then return, time_axis
  
  energy_eges = [(*self.bins).energy_start, (*self.bins).energy_end]
  energy_eges = energy_eges[sort(energy_eges)]
  energy_eges = energy_eges[uniq(energy_eges)]
  
  energy_axis = stx_energy_axis(edges=energy_eges)
    
  if keyword_set(energy) && ~keyword_set(time) then return, energy_axis
  
  return, {energy:energy_axis,time:time_axis}
end

;+
; :description:
;   querying interface to all stx_time_energy_bin members of the collection
;   finds all stx_time_energy_bins within the specified time energy range 
;   
; :keywords:
;   energy : in, type="double([start,end]|timepoint)"
;            specifies the time range or a timepoint
;            
;   time   : in, type="float([start,end]|energyvalue)"
;            specifies the energy band or value
;            
;   strict : in, type="[0|1]", default="0"
;            if set only time energy bins strict within the given range are found 
;            if not set also overlaps are found
;
;   idx    : in, type="[0|1]", default="0"
;            returns the index of all matches
;            
;   plotting: in, type="[0|1]", default="0"
;            if set do some plotting for debuging
;            
;   strict : in, type="int"
;            returns the number of found bins
;                        
; :returns:
;    all found time energy bins within the given time energy range 
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;     29-nov-2016, ECMD (Graz), changed behaviour of interval matching when the strict keyword is used. 
;                               If input time and energy is a single point only intervals strictly less than the upper
;                               boundaries are selected but if a range is input all intervals within the given boundaries will be selected.  
;     15-dec-2016, ECMD (Graz), changed behaviour of interval matching when the strict keyword is used.      
;                               If input time and energy is a single point a null result will be returned
;                               if a range is input all intervals within the given boundaries will be selected.  
;                               
;-
function stx_time_energy_bin_collection::select, time=time, energy=energy, strict=strict, count_matches=count_matches, plotting=plotting, idx=idx, all=all, type=type
  default, plotting, 0
  default, all, 0
  default, strict, 0

  if ~ptr_valid(self.bins) then begin
    count_matches = 0
    return, !NULL
  endif
  
  if ~keyword_set(time) && ~keyword_set(energy) then all=1
  if all then begin
    count_matches = n_elements(*(self.bins))
    matches = lindgen(count_matches)
    iv = *(self.bins)
  endif else begin 
    
    if n_elements(time) gt 0 && ~ppl_typeof(time,compareto="stx_time",/raw) then message, "The given time range has to by of type stx_time" 
    
    case (n_elements(time)) of
      0:    time_span = self->get_boundingbox(/time)
      1:    time_span = [time,time]
      2:    time_span = time
      else: time_span = time[0,-1]
    endcase
    
    ;convert the stx_time to internal time format
    time_span = anytim(time_span.value)
    
    case (n_elements(energy)) of
      0:    energy_range = self->get_boundingbox(/energy)
      1:    energy_range = [energy,energy]
      2:    energy_range = energy[sort(energy)]
      else: energy_range = minmax(energy)
    endcase
    
    iv = *(self.bins)
    
 if strict then begin
  
 if (time_span[0] eq time_span[1] and energy_range[0] eq energy_range[1]) then $
  print, 'Warning: when strict keyword is used and input time and energy is a single point a null result will be returned.'

  matches = where(iv.time_start ge time_span[0] $
          AND iv.time_end le time_span[1] $
          AND iv.energy_start ge energy_range[0] $
          AND iv.energy_end le energy_range[1], count_matches)
          
    endif else begin

      matches = where((iv.time_start ge time_span[0] OR iv.time_end ge time_span[0]) $
        AND (iv.time_end lt time_span[1] OR iv.time_start lt time_span[1]) $
        AND (iv.energy_start ge energy_range[0] OR iv.energy_end ge energy_range[0]) $
        AND (iv.energy_end lt energy_range[1] OR iv.energy_start lt energy_range[1]), count_matches)

    end


    if plotting then begin
       tvlct, r0, g0, b0, /get
       loadct, 39, /silent
      self->plot_grid, linestyle=1, /ylog ;,ystyle=1, xstyle=1 
      
      for i=0l, count_matches-1 do begin
        box = iv[matches[i]]
        rectangle, box.time_start, box.energy_start, box.time_end - box.time_start, box.energy_end - box.energy_start, linestyle=0,color = 250
      end
      rectangle, time_span[0], energy_range[0], time_span[1]-time_span[0], energy_range[1]-energy_range[0], linestyle=3, color = 100
      tvlct, r0, g0, b0
    
     endif ;plotting
  endelse ;search
  
  ;filter type
  if keyword_set(type) && count_matches gt 0 then begin
    filtered_idx = where(iv[matches].data_type eq type, count_matches)
    if count_matches gt 0 then matches = matches[filtered_idx] 
  end
  
  ;return the indexes of the found bins
  if keyword_set(idx) then return, matches
  
  ;return all found bins or an empty list
  if count_matches le 0 then return,  !NULL
  
  ;autocast or return poibnter array
  if keyword_set(type) then begin
    data = replicate(*((iv[matches])[0].data),count_matches)
    for i=0L, count_matches-1 do data[i]=*((iv[matches])[i].data)
    return, data
  endif else begin
    return, iv[matches].data
  endelse
    
end

pro stx_time_energy_bin_collection::remove, idx, all=all, type=type
  
  
  if ~ptr_valid(self.bins) then return
  
  n_bins = n_elements(*self.bins)
  
  if keyword_set(all) then idx=lindgen(n_bins) else begin
    idx = abs(fix(idx))
    ok = where(idx lt n_bins, n_outs)
    if n_outs gt 0 then  idx=idx[ok]  
  endelse 
  
 
  ;filter type
  if keyword_set(type) && n_elements(idx) gt 0 then begin
    filtered_idx = where((*self.bins)[idx].data_type eq type, count_matches)
    if count_matches gt 0 then idx = idx[filtered_idx] else return 
  end
  
  remains_idx = intarr(n_bins)
  remains_idx[idx] = 1
    
  void = where(remains_idx eq 1, complement=remains_idx, ncomplement=ncomplement)
  
  destroy, (*self.bins)[idx].data
  
  if ncomplement gt 0 then *self.bins = (*self.bins)[remains_idx] else self.bins = ptr_new()
   
end


;+
; :description:
;    plots the borders of all collection members
;
; :keywords:
;    _EXTRA : passed to plotting methods (plot and rectangle)
;
; :author: nicky.hochmuth
;-
pro stx_time_energy_bin_collection::plot_grid, _EXTRA=_EXTRA
  ranges = self->get_boundingbox()
  
  plot, anytim(ranges.time.value), ranges.energy, /nodata, _EXTRA=_EXTRA
  for i=0l, n_elements(*self.bins)-1 do begin
    iv = (*self.bins)[i]
    rectangle, iv.time_start, iv.energy_start, iv.time_end - iv.time_start, iv.energy_end - iv.energy_start,  _EXTRA=_EXTRA ;, color=total((*iv.data).counts)/3000. * 255
  end
end


;+
; :description:
;     destroys all members and the collection itself
;     
; :author: nicky.hochmuth
;-
pro stx_time_energy_bin_collection::cleanup
  
  if ptr_valid(self.bins) then begin
;    for i=0l, n_elements((*(self.bins)))-1 do begin
;       heap_free, ((*(self.bins))[i]).data
;       heap_free, (*(self.bins))[i]
;    end 
     heap_free, self.bins
  end
end

pro stx_time_energy_bin_collection__define
   compile_opt idl2, hidden
   void = { stx_time_energy_bin_collection, $
            bins       : ptr_new()}
end