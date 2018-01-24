;+
; :description:
;     This function loads the text file containing parameters of simulated 
;     sources and converts it to "stx_sim_source" structure
;
; :params:
;     filename : in, required, type="string"
;                the name of file containing parameters of simulated sources
; 
; :returns:
;     outtab : out, type="array of stx_sim_source structures"
;              structures are defined by procedure stx_sim_source_structure.pro
;              output array will contain parameters of simulated sources
;              
; :modification history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to use new tag
;                   names defined during merging with stx_sim_flare.pro
;     01-Nov-2013 - Shaun Bloomfield (TCD), structure tag names updated
;-
function stx_sim_load_tabstructure, filename
  finfo=file_info(filename)
  if finfo.read eq 0 then begin
      print,filename," - the file is not readable"
      return,0
  endif else begin
      openr, lun, filename, /get_lun
      line=''
      n=0
      while ~ EOF(lun) do begin
        readf, lun, line
        if strpos(strcompress(line, /REMOVE_ALL),'#') ne 0 then begin
          columns=strsplit(strcompress(line)," ", /EXTRACT)
          n0=n_elements(columns)
          if n0 gt 6 then begin
            elem=stx_sim_source_structure()
            if  0 lt n0 then elem.source=long(columns[0])
            if  1 lt n0 then elem.shape=columns[1]
            if  2 lt n0 then elem.xcen=double(columns[2])
            if  3 lt n0 then elem.ycen=double(columns[3])
            if  4 lt n0 then elem.duration=double(columns[4])
            if  5 lt n0 then elem.flux=double(columns[5])
            if  6 lt n0 then elem.distance=double(columns[4])
            if  7 lt n0 then elem.fwhm_wd=double(columns[6])
            if  8 lt n0 then elem.fwhm_ht=double(columns[7])
            if  9 lt n0 then elem.phi=double(columns[8])
            if 10 lt n0 then elem.loop_ht=double(columns[9])
            if n eq 0 then outtab=[elem] else outtab=[outtab,elem]
            n++
          endif
        endif
      endwhile
      close, lun
      free_lun, lun
      if n eq 0 then begin
        print,filename," - the file is empty"
        return,0
      endif
      return,outtab
  endelse
end
