;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_unique_filename
;
; :purpose:
;       Return a unique file path that does not yet exist on disk.
;       If the requested path already exists an integer counter suffix
;       is appended to the base name (before the extension) and incremented
;       until a free name is found, e.g.
;           stx_spectrum_12345.fits  ->  stx_spectrum_12345_1.fits
;           stx_spectrum_12345_1.fits -> stx_spectrum_12345_2.fits
;
; :category:
;       helper methods
;
; :params:
;       filename : in, required, type="string"
;                  Desired output file path (must end in a recognised extension
;                  such as '.fits').
;
; :returns:
;       String containing a file path that does not exist on disk. If
;       filename itself does not exist it is returned unchanged.
;
; :calling sequence:
;       IDL> safe_name = stx_unique_filename('stx_spectrum_12345.fits')
;
; :history:
;       04-May-2026 - (Copilot), initial release
;
;-
function stx_unique_filename, filename

  ; Return immediately if the file does not yet exist
  if ~file_test(filename) then return, filename

  ; Identify the extension boundary (last '.' in the name)
  dot_pos = strpos(filename, '.', /reverse_search)
  if dot_pos lt 0 then begin
    ; No extension found – append counter directly to the end
    base = filename
    ext  = ''
  endif else begin
    base = strmid(filename, 0, dot_pos)
    ext  = strmid(filename, dot_pos)
  endelse

  counter = 1
  candidate = base + '_' + strtrim(counter, 2) + ext
  while file_test(candidate) do begin
    counter   = counter + 1
    candidate = base + '_' + strtrim(counter, 2) + ext
  endwhile

  return, candidate

end
