;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_date2min_time
;
; :description:
;    This function returns the filename corresponding to the lookup table corresponding to the minimum time
;    bin set on STIX on a given date.
;
; :categories:
;    spectroscopy, lightcurve
;
; :params:
;    date : in, required, type="string"
;           The date of observation in anytim format
;
; :returns:
;    minimum time bin size in centiseconds for given day
;
; :examples:
;    min_time = stx_date2min_time('2021-04-17')
;
; :history:
;    09-Aug-2022 - ECMD (Graz), initial release;
;-
function stx_date2min_time, date

  min_time_index = loc_file( 'min_time_index.csv', path = getenv('stx_det'))

  str_index = read_csv(min_time_index, n_table_header = 1)

  file_index = value_locate(anytim(str_index.FIELD2), anytim(date))

  min_time = (str_index.FIELD4)[file_index]

  return, min_time
end
