;+
; :description:
;   structure that contains the flare flag module information / results
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized structure
;
; :history:
;     10-May-2016 - Laszlo I. Etesi (FHNW), initial release
;
;-
function stx_fsw_flare_list_entry, $
    fstart  = fstart, $
    fend    = fend, $
    fbc     = fbc, $
    zloc    = zloc, $
    yloc    = yloc, $
    fsbyte  = fsbyte, $ 
    ended   = ended
  
  
  default, fstart, stx_time()
  default, fend, stx_time()
  default, fbc, 0
  default, zloc, 0
  default, yloc, 0
  default, fsbyte, 0b
  default, ended, 1b
  
  
  
  return, { $
      type    : 'stx_fsw_flare_list_entry', $
      fstart  : fstart, $
      fend    : fend, $
      ended   : ended, $
      fbc     : fbc, $
      zloc    : zloc, $
      yloc    : yloc, $
      fsbyte  : byte(fsbyte) $
    }
end