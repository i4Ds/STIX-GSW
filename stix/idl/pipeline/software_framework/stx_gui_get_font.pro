;+
; :file_comments:
;     Get the fonts for the STIX GUI. There exist 4 different font weights:
;       - font
;       - small_font
;       - big_font
;       - huge_font
;       
;     This procedure is based on hsi_ui_getfont.pro from the HESSI project.
;     
; :categories:
;     Software Framwork, GUI
;     
; :examples:
;
; :history:
;    22-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
; 	 Creating and returning fonts for the STIX GUI.
;
; :Params:
;    font
;    big_font
;
; :Keywords:
;    small_font
;    huge_font
;
; :returns:
;
; :history:
; 	 22-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_get_font, font, big_font, small_font=small_font, huge_font=huge_font

  compile_opt idl2
  
  ; Distinguish between Windows OS, Mac OS and other OSs
  case !version.os_family of
      'Windows' : begin
        font = 'MS Sans Serif*12'
        small_font = 'MS Sans Serif*10'
        big_font = 'Arial*Bold*24'
        huge_font = 'Arial*Bold*36'
        end
      'MacOS' : begin
        font = 'helvetica*10'
        small_font = 'helvetica*8'
        big_font = 'helvetica*14'
        huge_font = 'helvetica*18'
        end
      else: begin
          font = get_dfont(['-adobe-helvetica-medium-r-normal--10-*-*-*', $
                                   '-adobe-times-medium-r-normal--10-*-*-*'])
          small_font = get_dfont(['-adobe-helvetica-medium-r-normal--8-*-*-*', $
                                   '-adobe-times-medium-r-normal--8-*-*-*'])
      big_font = get_dfont(['-adobe-helvetica-bold-r-normal--14-*-*-*', $
                                   '-adobe-times-medium-r-normal--14-*-*-*'])
          huge_font = get_dfont(['-adobe-helvetica-bold-r-normal--24-*-*-*', $
                                   '-adobe-times-medium-r-normal--24-*-*-*'])
          end
  endcase
  ; Set the fonts
  font = font[0]
  small_font = small_font[0]
  big_font = big_font[0]
  huge_font = huge_font[0]
end