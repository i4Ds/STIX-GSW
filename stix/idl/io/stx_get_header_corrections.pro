pro stx_get_header_corrections, fits_path, distance = distance, time_shift = time_shift

primary_header = headfits(fits_path)

au = wcs_au()
  
distance_sun_m = (sxpar(primary_header, 'DSUN_OBS'))

distance = distance_sun_m/au

time_shift = (sxpar(primary_header, 'EAR_TDEL'))

end