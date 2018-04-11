;+
; :description:
;    This function reads in a radiation database fits file and outputs either the parameters for a specified time or the full contents of the fits file
;     as a stx_rad_database_str structure for a single time or structure array for the full database.

;
; :categories:
;    calibration, database
;
;
; :keywords:
;
;    filename : in,  type="string", default="'test_rad_db.fits'"
;                the name of the database fits file
;
;    time : in, type ="anytim readable format "
;           the time for which the radiation damage parameters should be returned
;
;    fulldb : in, type="bool", default="0"
;             if set returns the full database from the file instead of a single record
;
; :returns:
;    stx_rad_database_str
;
; :examples:
;    result = stx_read_radiation_database(filename = 'test_rad_db.fits', /fulldb)
;
; :history:
;    29-Mar-2018 - ECMD (Graz), initial release
;
;-
function stx_read_radiation_database, filename =filename, time = time, fulldb = fulldb

  default, filename, 'rad_dbase.fits'
  default, fulldb, 0

  dbase_str = mrdfits(filename,1,/silent)
  dbase_times = dbase_str.time
  ntimes = n_elements(dbase_times)

  if keyword_set(fulldb) then begin
    dbase_out = replicate(stx_rad_database_str(),ntimes)
    dbase_out.time = dbase_str.time
    dbase_out.det_mask = dbase_str.det_mask
    dbase_out.pix_mask = dbase_str.pix_mask
    dbase_out.params =   dbase_str.params
    return, dbase_out

  endif else begin

    if n_elements(time) eq 0 then print, 'No input time specified, using latest database entry: '+ atime( dbase_times[1])
    default, time,  dbase_times[-1]

    t = anytim(time)

    later = where(dbase_times gt t, nlater)

    case 1 of
      t gt max(dbase_times) : begin
        ;time is after all database entries:
        outstr = dbase_str[-1]
        print, 'Selected time is after all database entries - using last available time’
      end

      t lt min(dbase_times) : begin
        ;time is before all database entries:
        outstr = dbase_str[0]
        print, 'Selected time is before all database entries - using first available time’
      end
      else: begin

        tuse = value_locate(dbase_times, t )
        outstr = dbase_str[tuse]

      endelse
    endcase


  endelse

  return, outstr

end

