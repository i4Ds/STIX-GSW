;+
; :file_comments:
;    Helper procedure to start the analysis software GUI.
;    
; :categories:
;    analysis software, gui
;    
; :examples:
;    stx_analysis_software_gui
;           Opens a new analysis software GUI
;    
; :history:
;    01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
; 	 Opens a new analysis software GUI
;
; :returns:
;    -
;    
; :history:
; 	 01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_analysis_software_gui
  asw_o = obj_new('stx_asw_gui')
end