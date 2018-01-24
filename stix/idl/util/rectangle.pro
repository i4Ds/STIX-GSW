;+
; NAME:
; 
;       RECTANGLE
;   
; PURPOSE:
; 
; Draw a rectangle on a plot.
;   
; CALLING SEQUENCE:
; 
; RECTANGLE,X0,Y0,XLENGTH,YLENGTH
;   
; INPUTS:
;
;       X0, Y0 - Points specifying a corner of the rectangle.
;
;       XLENGTH, YLENGTH - the lengths of the sides of the rectangle,
;                          in data coords.
;       
; KEYWORD PARAMETERS:
; 
;       FILL = set to fill rectangle.
;   
;       FCOLOR = fill color.
;   
;       Graphics keywords: CHARSIZE,COLOR,LINESTYLE,NOCLIP,
;       T3D,THICK,Z,LINE_FILL,ORIENTATION,DEVICE
;   
; MODIFICATION HISTORY:
; 
; D. L. Windt, Bell Laboratories, September 1990.
; 
;       Added device keyword, January 1992.
;
;       windt@bell-labs.com
;   
;-

pro rectangle,x0,y0,xlength,ylength, $
              color=col,linestyle=lin, $
              noclip=noc,t3d=t3d,thick=thi,zvalue=zva, $
              fill=fill,fcolor=fcolor,line_fill=line_fill, $
              orientation=orientation, $
              device=device
on_error,2

if keyword_set(col) then color=col else color=!p.color
if keyword_set(lin) then linestyle=lin else linestyle=!p.linestyle
if keyword_set(noc) then noclip=1 else noclip=!p.noclip
if keyword_set(thi) then thick=thi else thick=!p.thick
if keyword_set(t3d) then t3d=t3d else t3d=!p.t3d
if keyword_set(zva) then zvalue=zva else zvalue=0
if keyword_set(fcolor) eq 0 then fcolor=color
if keyword_set(orientation) eq 0 then orientation=0
if keyword_set(device) eq 0 then device=0

if keyword_set(fill) then $
  polyfill,[x0,x0+xlength,x0+xlength,x0,x0], $
  [y0,y0,y0+ylength,y0+ylength,y0],color=fcolor, $
  line_fill=keyword_set(line_fill),orientation=orientation,device=device

plots,[x0,x0+xlength,x0+xlength,x0,x0],[y0,y0,y0+ylength,y0+ylength,y0], $
  color=color,linestyle=linestyle,noclip=noclip,thick=thick,t3d=t3d, $
  z=zvalue,device=device

return
end
