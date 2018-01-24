PRO PS_ON, $
   FILENAME  = filename, $
   PAPER     = paper, $
   PAGE_SIZE = page_size, $
   LANDSCAPE = landscape, $
   MARGIN    = margin, $
   INCHES    = inches, $
   VERBOSE   = verbose, $
   QUIET     = quiet

;+
; Name:
;      PS_ON
; Purpose:
;      Save current graphics device information, change the graphics output device to 
;      PostScript (PS), and configure the PS device.
;
;      This program uses the size of the current device (usually X or WIN) to set the
;      size of the vector fonts for Postscript device.  Therefore, the normal way to use 
;      this program is to draw the plot once on the windowing device, then run the
;      program again and use PS_ON to switch to the Postscript device.  When the graphics
;      are finished, use PS_OFF to close the Postscript device and switch back to the
;      previous device.
; Calling sequence:
;      PS_ON
; Input:
;      None.
; Output:
;      None.
; Keywords:
;      FILENAME  : optional PostScript output file name.  The default is 'idl.ps'.
;      PAPER     : optional string specifying the paper size.  Must be one of the 
;                  following:  LETTER, LEGAL, TABLOID, EXECUTIVE, A4, A3.  If neither  
;                  PAPER nor PAGE_SIZE is set, the default paper size is LETTER.
;                  Non-U.S. users may want to change the default to 'A4' below.
;      PAGE_SIZE : optional two-element array specifying the width and height of the paper 
;                  in cm (or inches if INCHES keyword is set).  If set, the value of PAPER
;                  is ignored.
;      LANDSCAPE : if set, output is oriented in LANDSCAPE mode.
;      MARGIN    : optional margin size in cm (or inches if INCHES keyword is set).  
;                  The default is 2.54 cm (1 inch).
;      INCHES    : if set, PAGE_SIZE and MARGIN are assumed to be in inches instead of cm.
;      VERBOSE   : if set, print detailed information about the initial device and the
;                  PS device.
;      QUIET     : if set, supress routine messages.
; Common blocks:
;      PS_INFO   : contains stored device information
; Author and history:
;      Kenneth P. Bowman, 2004-12.  Based on PSON by Liam Gumley, in Practical IDL Programming.
;      Unlike Gumley's PSON, this procedure does not set the aspect ratio of the PostScript
;      plotting area to be the same as the most recent graphics window.  It uses the full
;      area of the selected paper size less equal margins on all four sides.
;-

COMPILE_OPT IDL2                                                         ;Set compile options

COMMON PS_INFO, info                                                     ;Common block to store device information

IF (!D.NAME EQ 'PS') THEN BEGIN                                          ;Check active device
  MESSAGE, 'PostScript device already active.', /CONTINUE
  RETURN
ENDIF

IF (N_ELEMENTS(filename) EQ 0) THEN filename = 'idl.ps'                  ;Default output file name
IF (N_ELEMENTS(paper)    EQ 0) THEN paper    = 'LETTER'                  ;Default paper size
IF (N_ELEMENTS(margin)   EQ 0) THEN $
	margin   = 2.54 $                                                     ;Default margin size (cm)
ELSE $
	IF KEYWORD_SET(inches) THEN margin = 2.54*margin                      ;Convert margin size to inches

IF KEYWORD_SET(verbose) THEN BEGIN
	PRINT, 'Current device information :'
	HELP, /DEVICE                                                         ;Print current device information
	HELP, !D, /STR                                                        ;Print current device system variable
ENDIF

xratio = FLOAT(!D.X_CH_SIZE)/FLOAT(!D.X_VSIZE)                           ;Current relative character width
yratio = FLOAT(!D.Y_CH_SIZE)/FLOAT(!D.Y_VSIZE)                           ;Current relative character height

info =  {device     : !D.NAME, $                                         ;Save device name
         window     : !D.WINDOW, $                                       ;Save window index
         font       : !P.FONT, $                                         ;Save font setting
         color      : !P.COLOR, $                                        ;Save foreground color
         background : !P.BACKGROUND}                                     ;Save background color

name   = [     'LETTER', 'LEGAL', 'TABLOID', 'EXECUTIVE', 'A4', 'A3']    ;Paper names
width  = [2.54*[ 8.5,     8.5,    11.0,       7.25],      21.0, 29.7]    ;Paper widths (cm)
height = [2.54*[11.0,    14.0,    17.0,      10.50],      29.7, 42.0]    ;Paper heights (cm)
i      = (WHERE(STRUPCASE(paper) EQ name, count))[0]                     ;Find paper name
IF (count NE 1) THEN MESSAGE, 'PAPER selection not supported.'           ;Print error message and stop
page_width  = width[i]                                                   ;Save paper width
page_height = height[i]                                                  ;Save paper height

IF (N_ELEMENTS(page_size) EQ 2) THEN BEGIN
  page_width  = page_size[0]                                             ;Use user-supplied paper width
  page_height = page_size[1]                                             ;Use user-supplied paper height
  IF KEYWORD_SET(inches) THEN BEGIN
    page_width  = 2.54*page_width                                        ;Convert width to cm
    page_height = 2.54*page_height                                       ;Convert height to cm
  ENDIF
ENDIF

IF(KEYWORD_SET(landscape)) THEN BEGIN
   xsize   = page_height - 2.0*margin                                    ;Width for landscape mode
   ysize   = page_width  - 2.0*margin                                    ;Height for landscape mode
   xoffset = margin                                                      ;x-offset for landscape mode
   yoffset = page_height - margin                                        ;y-offset for landscape mode
ENDIF ELSE BEGIN
   xsize   = page_width  - 2.0*margin                                    ;Width for portrait mode
   ysize   = page_height - 2.0*margin                                    ;Height for portrait mode
   xoffset = margin                                                      ;x-offset for portrait mode
   yoffset = margin                                                      ;y-offset for portrait mode
ENDELSE

SET_PLOT, 'PS'                                                           ;Set device to Postscript
DEVICE, LANDSCAPE = KEYWORD_SET(landscape), SCALE_FACTOR = 1.0           ;Set orientation and scale
DEVICE, XSIZE   = xsize,   $                                             ;Set page sizes and offsets (cm)
        YSIZE   = ysize,   $
        XOFFSET = xoffset, $
        YOFFSET = yoffset
DEVICE, FILENAME = filename, /COLOR, BITS_PER_PIXEL = 8                  ;Set color mode
DEVICE, SET_CHARACTER_SIZE=[ROUND(xratio*!D.X_VSIZE), $                  ;Set font size
                            ROUND(yratio*!D.Y_VSIZE)]

IF KEYWORD_SET(verbose) THEN BEGIN
	PRINT, 'Postscript device information :'
	HELP, /DEVICE                                                         ;Print current device information
	HELP, !D, /STR                                                        ;Print current device system variable
ENDIF

IF ~KEYWORD_SET(quiet) THEN PRINT, 'Starting PS output to ', filename    ;Print message

END
