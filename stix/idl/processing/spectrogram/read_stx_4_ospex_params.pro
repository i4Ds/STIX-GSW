pro read_stx_4_ospex_params, filename, param, status

  status = 0

  ; If Object Parameter extension is there, move subset of tags we need to a new structure to
  ; save time (str_top2sub is slow)

  p_ext = get_fits_extno(filename, 'STIX Spectral Object Parameters')
  if p_ext ne -1 then begin
    struct = mrdfits(filename, p_ext, /silent)
    tags = tag_names(struct)
    tag_list = ['SP_ATTEN_STATE', 'INTERVAL_ATTEN_STATE', 'USED_XYOFFSET' ]
    for i=0,n_elements(tag_list)-1 do begin
      q = where (strpos(tags, tag_list[i]) eq 0, count)
      if count gt 0 then tags_to_use = append_arr(tags_to_use, tags[q])
    endfor

    if exist(tags_to_use) then begin
      new_struct = str_subset(struct, tags_to_use)
      param = str_top2sub( new_struct )
      status = 1
    endif
  endif

end
