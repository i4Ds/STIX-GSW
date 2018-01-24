;---------------------------------------------------------------------------
; Document name: cmphase.pro
; Created by:    nicky.hochmuth 29.08.2012
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME: cmphase
;
; PURPOSE: calculates the phase of a complex number
;
; CATEGORY: stix helper functions
;
; CALLING SEQUENCE:
;
;
; :history:
;    23.08.2012 nicky.hochmuth initial release
;    2013-06-26, Laszlo I. Etesi (FHNW), replaced "atan" with "arctan", using !RADEG
;-
;+
; :description:
;    calculates the phase of a complex number
;
; :params:
;    z the complex input
;
; :keywords:
;    degrees : rad or degrees
;
; returns
;-
function cmphase, z, degrees=degrees
   ; check input
   if(n_params()) eq 0 then begin
      message, "  usage:  cmphase(z[,/degrees]"
      return, 0
   endif
   
   ; calculate phase in rad and deg
   arctan, real_part(z), imaginary(z), phase_rad, phase_deg
;   print, z
;   print, phase_rad
;   print, phase_deg
   if(keyword_set(degrees)) then return, phase_deg $
   else return, phase_rad
end