; $Id: //depot/Release/ENVI50_IDL82/idl/idldir/lib/graphics/legend.pro#1 $
;
; Copyright (c) 2000-2012, Exelis Visual Information Solutions, Inc. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;----------------------------------------------------------------------------
;+
; :Description:
;    Create IDL Legend graphic.
;
; :Params:
;    
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;    
; :author:
;    19-Aug-2014 - Laszlo I. Etesi, copied from IDL to override existing legacy override
;-
function legend, DEBUG=debug, _REF_EXTRA=_extra
  compile_opt idl2, hidden
@graphic_error

  return, OBJ_NEW('Legend', HORIZONTAL_ALIGNMENT='right', _EXTRA=_extra)

end