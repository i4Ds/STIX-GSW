;+
; :description:
;   This routine tries to find a file inside a folder recursively
;
; :params:
;    filename : in, required, type='string'
;      the file to search
;
; :keywords:
;    dir : in, optional, type='string', default='curdir()'
;      this is the base directory to start the search
;    type : in, optional, type='bool', default='false'
;      defines if subfolder should be searched
;      
; :returns:
;    the file name and path if the file was found, zero otherwise
;      
; :categories:
;    utility, pipeline, file search
;    
; :examples:
;    print, ppl_search_file('stx_data_simulation__define.pro', /descend')
;    
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release (of doc)
;-
function ppl_search_file, filename, dir=dir, descend=descend
  checkvar, dir, curdir()
  ;  Check if beginning of current directory is a directory 
  ;  deliminator (definitely occurs in Mac OS)
  preceding = strmid(dir, 0, 1) eq get_delim()
  
  split_path = strsplit(dir, get_delim(), /extract, count=no_splits)
  for index = 1, no_splits do begin
     ;  Add preceding directory deliminator if found above
     cur_path = (['', get_delim()])[preceding] + arr2str(split_path[0:(no_splits-index)], get_delim())
     
     if(keyword_set(descend)) then found = file_search(cur_path, filename) $
     else found = file_search(cur_path + get_delim() + filename)
     
     if (found[0] ne '') then return, found
  endfor
end
