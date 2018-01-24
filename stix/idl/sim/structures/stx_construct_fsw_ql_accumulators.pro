
pro _handle_add_tag_duplicate, struct, tag, duplicate
  compile_opt hidden
  
  if(tag_exist(struct, tag)) then begin
    switch (duplicate) of
      0: begin
        message, 'Duplicate quicklook accumulator detected: ' + tag
        break
      end
      1: begin
        print, 'Duplicate quicklook accumulator detected: ' + tag + '. Ignoring newer version.'
        break
      end
      2: begin
        local_ql_accumulators = rem_tag(struct, tag)
        print, 'Duplicate quicklook accumulator detected: ' + tag + '. Replacing it with newer version.'
      end
    endswitch
  endif
end


function stx_construct_fsw_ql_accumulators, qlook_acc_config_file, ql_accumulators_struct=ql_accumulators_struct, ql_accumulator_struct=ql_accumulator_struct, _extra=extra, duplicate=duplicate
  default, duplicate, 0
  
  if(isvalid(ql_accumulators_struct)) then begin
    ppl_require, type='stx_fsw_ql_accumulators', ql_accumulators_struct=ql_accumulators_struct
    local_ql_accumulators = ql_accumulators_struct
  endif else local_ql_accumulators = stx_fsw_ql_accumulators()
  
  ; read-in allowed quicklook types
  default, qlook_acc_config_file , concat_dir( getenv('STX_CONF'), 'qlook_accumulators.csv' )
  qlook_acc_config_struct = stx_fsw_ql_accumulator_table2struct(qlook_acc_config_file)
  
  allowed_types = 'stx_fsw_ql_' + qlook_acc_config_struct.accumulator
  
  if(isvalid(ql_accumulator_struct)) then begin
    ppl_require, type=allowed_types, ql_accumulator_struct=ql_accumulator_struct
    _handle_add_tag_duplicate, local_ql_accumulators, ql_accumulator_struct.type, duplicate
    local_ql_accumulators = add_tag(local_ql_accumulators, ql_accumulator_struct, ql_accumulator_struct.type, /quiet)
  endif
  
  if(isvalid(extra)) then begin
    tags = strlowcase(tag_names(extra))
    for index = 0L, n_elements(tags)-1 do begin
      keyword_idx = where(allowed_types eq tags[index])
      
      if(max(keyword_idx) eq -1) then message, 'Incorrect quicklook accumulator name. Actual: ' + tags[index] + '. Expected: ' + arr2str(allowed_types)
      ppl_require, keyword=tags[index], type=allowed_types, _extra=extra
      _handle_add_tag_duplicate, local_ql_accumulators, tags[index], duplicate
      local_ql_accumulators = add_tag(local_ql_accumulators, extra.(index), tags[index], /quiet)
    endfor
  endif
  
  return, local_ql_accumulators
end