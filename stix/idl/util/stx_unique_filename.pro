;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_unique_filename
;
; :purpose:
;       Return a unique FITS file path that does not yet exist on disk.
;       If the requested path already exists an integer counter suffix
;       is appended to the base name (before the .fits extension) and
;       incremented until a free name is found, e.g.
;           stx_spectrum_12345.fits    ->  stx_spectrum_12345_1.fits
;           stx_spectrum_12345_1.fits  ->  stx_spectrum_12345_2.fits
;
; :category:
;       helper methods
;
; :params:
;       filename : in, required, type="string"
;                  Desired output FITS file path.
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

  if ~file_test(filename) then return, filename

  ext  = '.fits'
  base = file_dirname(filename, /mark_directory) + file_basename(filename, ext)

  counter = 1
  candidate = base + '_' + strtrim(counter, 2) + ext
  while file_test(candidate) do begin
    counter   = counter + 1
    candidate = base + '_' + strtrim(counter, 2) + ext
  endwhile

  return, candidate

end
