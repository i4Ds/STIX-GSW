;+
; :Name:
;   stx_science_energy_channels
; :Description:
;    This function returns the science energy bins. It reads the data file and holds the result
;    in a common block only accessed by this routine
; :Examples:
;      IDL> str = stx_science_energy_channels(/str)
;      IDL> help, str,/st
;      ** Structure <d3d9df0>, 9 tags, length=48, data length=42, refs=1:
;         TYPE            STRING    'stx_science_energy_channel'
;         CHANNEL_NUMBER  INT              0
;         CHANNEL_EDGE    INT              0
;         ENERGY_EDGE     FLOAT           4.00000
;         ELOWER          FLOAT           4.00000
;         EUPPER          FLOAT           5.00000
;         BINWIDTH        FLOAT           1.00000
;         DE_E            FLOAT          0.222000
;         QL_CHANNEL      INT              0
;      IDL> help, str
;      STR             STRUCT    = -> <Anonymous> Array[33]
;      IDL> str = stx_science_energy_channels(/edges_2)
;      IDL> help, str
;      STR             FLOAT     = Array[2, 32]
;      IDL> help, stx_science_energy_channels(/ql, /str)
;      <Expression>    STRUCT    = -> <Anonymous> Array[6]
;      IDL> print, stx_science_energy_channels(/ql, /edges_1)
;            4.00000      10.0000      15.0000      25.0000      50.0000      150.000
; :Keywords:
;    basefile - filename of csv file in $STX_DET, default is 'EnergyBinning20150615.csv'
;     In the futre the basefile name will be under some configuration control
;    reset - if reset, force the data file to be reread into common
;    structure - if set, return the science energy channels as a full structure
;    
;    _extra - keywords for get_edges()
;    ql  - if set, report the quicklook energy channels
;
; :Author: richard.schwartz@nasa.gov, 29-jun-2015
;-
function stx_science_energy_channels, $
  basefile = basefile, reset=reset, structure = structure, ql = ql, _extra = _extra

common stx_science_energy_channels, energy_channels_str
default, ql, 0 ;report quicklook channels if set
default, reset, 0
default, basefile, 'EnergyBinning20150615.csv'
if reset or ~is_struct( energy_channels_str ) then begin
  
  file  = concat_dir( getenv('STX_DET'), basefile)
  out   = read_csv( file, head=head, record_start=24, table_header=tbl)
  names = rd_tfile(file)
  
  z     = where( stregex( names, 'channel number',/fold, /boo))
  names = strtrim( str2arr( delim=',',names[z]), 2)
  
  z     = where( names eq 'dE/E')
  
  names[z] = 'de_E'
  names = [ 'type', names ]
  str   = replicate( create_struct( names[0:8], 'stx_science_energy_channel', 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0), 33)
  s     = reform_struct( out )
  for i = 1, 8 do str.(i) = s.(i-1)
  for i = 1, 8 do str[32].(i) = str[32].(i) eq 0 ? -1 : str[32].(i)
  energy_channels_str = str
endif else str = energy_channels_str

;For the quicklook energy bins
if keyword_set( ql ) then $
  str = str[ [ 0, where( str[1:*].ql_channel - str.ql_channel ) + 1 ]  ]
  
 
result = keyword_set( structure ) ? str : get_edges( str.energy_edge, _extra = _extra )

 
return, result
end

