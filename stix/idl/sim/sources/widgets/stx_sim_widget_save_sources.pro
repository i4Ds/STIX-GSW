;+
; :description:
;     Widget handling saving of the table of the "stx_sim_source" structures
;     The data is saved using "stx_sim_save_tabstructure" procedure
;
; :params:
;     allelementsstructure  :  in, required, type="array of stx_sim_source structures"
;                              1D array of source structures
;     mainid                :  in, required, type="long"
;                              ID of the parent widget
;
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;-
pro stx_sim_widget_save_sources, allelementsstructure, mainid
     base = widget_base(group_leader=mainid,/column,column=1,title='save')
     fileid = cw_filesel(base, filter='all files', /warn_exist, /save) 
     outputfile=''  
     state = {file:outputfile, data:allelementsstructure}  
     widget_control, base, /realize
     widget_control, base, set_uvalue=state
     xmanager, 'stx_sim_widget_save_sources', base  
end
