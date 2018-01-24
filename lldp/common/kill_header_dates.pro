; Just a routine to obliterate times from certain keywords:
;
PRO kill_header_dates, h
  
  ;; If it's a primary header, then knock out date on SIMPLE
  ;;
  IF fxpar(h, 'SIMPLE') THEN fxaddpar, h, 'SIMPLE', 'T', ' Written by IDL <date withheld>'
  
  ;; If it's an extension, knock out the date on XTENSION
  ;;
  xtension = fxpar(h, 'XTENSION')
  IF typename(xtension) EQ 'STRING' THEN BEGIN
     fxaddpar, h, 'XTENSION', xtension, 'Written by IDL <date withheld>'
  END
END 

