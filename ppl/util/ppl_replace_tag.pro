;+
; :description:
;    adds or replace a tag to a structure and set the value
;    the tagname could by a full qualivied path in "sruct.tagname.tagname" syntax
;    
;
; :params:
;    struct : in, required,
;      the current structure
;    tag_name : in, required
;      name or path of the tag
;    new_value : in, required
;      the new value for the tag
     
; :returns:
;    a new struct with the updated or addet tag
;      
; :categories:
;    utility, legacy, pipeline
;    
; :examples:
;    str = {type:"test", tag1 : 2}
;    str = ppl_replace_tag(str, "tag2", {{type:"test2", subtag1 : 'foo'}})
;    str = ppl_replace_tag(str, "tag2.subtag2", 'bar')
;    str = ppl_replace_tag(str, "tag2.subtag1", 100)
;    print, str.tag2.subtag1 --> 100
;    
; :history:
;    2014/01/05 nicky.hochmuth@fhnw.ch, initial release
;-
function ppl_replace_tag, struct, tag_name, new_value
  
  if ~is_struct(struct) then return, struct
  if ~is_string(tag_name) then return, struct
  
  sub_structs = STRSPLIT(tag_name,'.', /EXTRACT )
  
  tag_name = sub_structs[0]
  tag_idx = tag_index(struct,tag_name)
  
  if n_elements(sub_structs) gt 1 then begin
    new_value = ppl_replace_tag(struct.(tag_idx),strjoin(sub_structs[1:n_elements(sub_structs)-1],'.'),new_value)
  end 
  
  new_str = tag_idx ge 0 ? rem_tag(struct,tag_idx) : struct
  new_str = CREATE_STRUCT(new_str, tag_name, new_value)
  
  return, new_str
end