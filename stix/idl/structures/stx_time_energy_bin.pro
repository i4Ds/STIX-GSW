;+
; :description:
;   This function creates a stx_time_energy_bin a data container for a given time energy range within a spectrogram
;
; :categories:
;    structures
;
; :params:
;    time_start   : type="double"
;                   the start time
;    time_end     : type="double"
;                   the end time
;    energy_start : type="float"
;                   the lover energy border
;    energy_end   : type="float"
;                   the upper energy border
;    data         : type="anytype"
;                   the dataobject the stx_time_energy_bin will reference to
; :returns:
;    a stx_time_energy_bin structure with the connected data element
;
; :examples:
;
; :history:
;     11-oct-2013, Nicky Hochmuth initial  
;-
function stx_time_energy_bin, struct    
    
    if N_PARAMS() eq 0 then begin
      stx_time_energy_bin = { $
        type          : 'stx_time_energy_bin', $
        time_start    : .0d, $ 
        time_end      : .0d, $
        energy_start  : .0, $ 
        energy_end    : .0, $
        data_type     : "", $
        data          : ptr_new() $
      }
    end else begin
      if ppl_typeof(struct,compareto='pointer') then struct = *struct
      if ~is_struct(struct) || $
         ~tag_exist(struct,'time_range') || $
         n_elements(struct.time_range) ne 2 || $
         ~ppl_typeof(struct.time_range,compareto='stx_time',/raw) || $
         ~tag_exist(struct,'energy_range') || $
         n_elements(struct.energy_range) ne 2 || $
         ~ppl_typeof(struct.energy_range,compareto='float',/raw)  || $
         ~tag_exist(struct,'type') || $
         ~ppl_typeof(struct.type,compareto='string',/raw) $
      then message, "all collection members has to be a struct or a pointer to a struct with tags: time_range of type stx_time(2) and energy_range of type float(2) "
      
      stx_time_energy_bin = { $
        type          : 'stx_time_energy_bin', $
        time_start    : stx_time2any(struct.time_range[0]), $ 
        time_end      : stx_time2any(struct.time_range[1]), $
        energy_start  : struct.energy_range[0], $ 
        energy_end    : struct.energy_range[1], $
        data_type     : struct.type, $
        data          : ptr_new(struct) $
      }
    endelse
 
 
 
 return, stx_time_energy_bin
end