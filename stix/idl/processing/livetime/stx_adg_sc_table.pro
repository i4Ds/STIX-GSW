;+
; :Description:
;    This function builds the correspondance table structure between the detector numbers (sc 1-32) and the
;    trigger accumulators numbers ( adg_idx 1-16 )
;
;
;
; :Keywords:
;    reset - reread the table, (for development only)
; :Common Block - adg_table, holds the resultant structure
; :Author: raschwar, 14-apr-2015
;          ECMD      16-dec-2020 updated ADG-SC Table in line with STIX-ICD-0812-ESC_I4R2_TMTC_ICD Fig 4.1 and Table 32 
;-
function stx_adg_sc_table, reset = reset

common adg_table, adg
;;;ADG-SC Table - Don't change these lines as they are used to build the table
; #    HV   Q    DG   SC    Y[mm]    Z[mm]
; 1    1    1    4    13     12.5     27.5
; 2    1    1    4    12     12.5     50.5
; 3    1    1    3    11     12.5     73.5
; 4    1    1    2     7     37.5     13.5
; 5    1    1    2     6     37.5     36.5
; 6    1    1    3     5     37.5     59.5
; 7    1    1    1     1     62.5     13.5
; 8    1    1    1     2     62.5     36.5
; 9    1    2    1    14     12.5    -27.5
;10    1    2    1    15     12.5    -50.5
;11    1    2    2    16     12.5    -73.5
;12    1    2    3     8     37.5    -13.5
;13    1    2    3     9     37.5    -36.5
;14    1    2    2    10     37.5    -59.5
;15    1    2    4     3     62.5    -13.5
;16    1    2    4     4     62.5    -36.5
;17    2    3    4    20    -12.5    -27.5
;18    2    3    4    21    -12.5    -50.5
;19    2    3    3    22    -12.5    -73.5
;20    2    3    2    26    -37.5    -13.5
;21    2    3    2    27    -37.5    -36.5
;22    2    3    3    28    -37.5    -59.5
;23    2    3    1    31    -62.5    -13.5
;24    2    3    1    32    -62.5    -36.5
;25    2    4    1    19    -12.5     27.5
;26    2    4    1    18    -12.5     50.5
;27    2    4    2    17    -12.5     73.5
;28    2    4    3    25    -37.5     13.5
;29    2    4    3    24    -37.5     36.5
;30    2    4    2    23    -37.5     59.5
;31    2    4    4    30    -62.5     13.5
;32    2    4    4    29    -62.5     36.5
if ~exist( adg ) or keyword_set( reset ) then begin
  chkarg,'stx_adg_sc_table', proc, /quiet
  hdr = where( strpos( proc, 'Z[mm]') ne -1)
  ;Parse the table from proc:
  tbl = reform( (fix( str2arr( strcompress( arr2str( strmid( proc[hdr[0]+1+lindgen(32)], 14, 10), ' ')),' ')))[1:64], 2, 32)
  ;   ADgroup(SC) = (Q(SC)-1)*4+DG(SC)
  ;
  ;
  dg  = reform( tbl[ 0, * ] )
  sc  = reform( tbl[ 1, * ] )
  adg = replicate( {dg: 0, sc: 0, q: 0, sc_twin: 0, adg_idx: 0}, 33 )
  adg[1:*].dg = dg
  adg[1:*].sc = sc
  adg[1:*].q  = indgen(32) / 8 + 1
  adg.adg_idx = ( adg.q - 1) * 4 + adg.dg > 0
  adg = adg[ sort(adg.adg_idx) ]
  adg[1:31:2].sc_twin = adg[2:32:2].sc
  adg[2:32:2].sc_twin = adg[1:31:2].sc
  endif
return, adg
end