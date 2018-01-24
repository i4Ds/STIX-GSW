PRO PS_OFF, QUIET = quiet

;+
; Name:
;      PS_OFF
; Purpose:
;      Close the PostScript (PS) output file and restore the
;      previous device configuration.
;
;      This procedure is used with PS_ON to switch to the PS device
;      and then back to the original device.
; Calling sequence:
;      PS_OFF
; Input:
;      None.
; Output:
;      None.
; Keywords:
;      QUIET : if set, supress routine messages.
; Common blocks:
;      PS_INFO : contains stored device information
; Author and history:
;      Kenneth P. Bowman, 2004-12.  Based on PSOFF by Liam Gumley, in 
;      Practical IDL Programming.
;-

COMPILE_OPT IDL2                                     ;Set compile options

COMMON PS_INFO, info                                 ;Common block to store device information

IF (!D.NAME NE 'PS') THEN BEGIN                      ;Check active device
   MESSAGE, 'PostScript device not active.  ' + $
      'No output file created.', /CONTINUE
   RETURN
ENDIF

IF (N_ELEMENTS(info) EQ 0) THEN BEGIN                ;Check saved device info
   MESSAGE, 'PS_ON must be called before PS_OFF.  ' + $
      'No output file created.', /CONTINUE
   RETURN
ENDIF

DEVICE, /CLOSE_FILE                                  ;Close PS device

SET_PLOT, info.device                                ;Restore previous device
IF (info.window GE 0) THEN WSET, info.window         ;Restore window
!P.FONT       = info.font                            ;Restore font
!P.COLOR      = info.color                           ;Restore foreground color
!P.BACKGROUND = info.background                      ;Restore background color

IF ~KEYWORD_SET(quiet) THEN PRINT, 'PS output ended.'

END
