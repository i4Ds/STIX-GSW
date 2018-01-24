;+
; :name:
;   stx_ltpair_assignment
; :description:
;   This function returns the STIX sub-collimator assignment pairings. The readouts for the Caliste modules
;   are done in groups of two. The livtime is determined by the rate of events on pairs of sub-collimators
;   and their active pixels. This function gives the other paired isc for a given input, isc_in.  It also
;   returns the whole set as a 2x16 array. You can access the sub-collimator(detector) index (1-32) and it's association
;   more directly by getting the structure, e.g.
;   adg = stx_adg_sc_table()
;   adg_sc = adg[ sort( adg.sc ) ]
;IDL> help, adg
;    ADG             STRUCT    = -> <Anonymous> Array[33]
;      
;      IDL> help, adg[1],/st
;      ** Structure <1323fb10>, 5 tags, length=10, data length=10, refs=4:
;      DG              INT              1
;      SC              INT             11
;      Q               INT              1
;      SC_TWIN         INT              5
;      ADG_IDX         INT              1
; :categories:
;    trigger, livetime
;
; :params:
;   isc_in - integer, scalar or vector, from 1-32, returns the pair ISC, NB, detector index is ISC-1
; :Keywords:
;   PAIRS - if set, return the grouped pair isc values as a 2x16 array
;   
;   ADGROUP_IDX - if set, return the correspondig analog digital converter units indices
;   
;   ADgroup(SC) = (Q(SC)-1)*4+DG(SC) 
;    
;    
; #    HV   Q    DG   SC    Y[mm]    Z[mm]
; 1    1    1    4    13     12.5     27.5
; 2    1    1    4    12     12.5     50.5
; 3    1    1    1    11     12.5     73.5
; 4    1    1    3     7     37.5     13.5
; 5    1    1    3     6     37.5     36.5
; 6    1    1    1     5     37.5     59.5
; 7    1    1    2     1     62.5     13.5
; 8    1    1    2     2     62.5     36.5
; 9    1    2    2    14     12.5    -27.5
;10    1    2    2    15     12.5    -50.5
;11    1    2    1    16     12.5    -73.5
;12    1    2    3     8     37.5    -13.5
;13    1    2    3     9     37.5    -36.5
;14    1    2    1    10     37.5    -59.5
;15    1    2    4     3     62.5    -13.5
;16    1    2    4     4     62.5    -36.5
;17    2    3    4    20    -12.5    -27.5
;18    2    3    4    21    -12.5    -50.5
;19    2    3    1    22    -12.5    -73.5
;20    2    3    3    26    -37.5    -13.5
;21    2    3    3    27    -37.5    -36.5
;22    2    3    1    28    -37.5    -59.5
;23    2    3    2    31    -62.5    -13.5
;24    2    3    2    32    -62.5    -36.5
;25    2    4    2    19    -12.5     27.5
;26    2    4    2    18    -12.5     50.5
;27    2    4    1    17    -12.5     73.5
;28    2    4    3    25    -37.5     13.5
;29    2    4    3    24    -37.5     36.5
;30    2    4    1    23    -37.5     59.5
;31    2    4    4    30    -62.5     13.5
;32    2    4    4    29    -62.5     36.5
;    
; :restrictions:
;     
; :Useage:
;    IDL> print, stx_ltpair_assignment( indgen(32)+1 )
;           2       1       4       3      11       7       6       9       8      16       5      13      12      15      14      10      23      19      18      21      20      28      17      25      24      27
;          26      22      30      29      32      31
;    IDL> print, stx_ltpair_assignment( [2,1])
;           1       2
;    IDL> print, stx_ltpair_assignment( [2,1,5])
;           1       2      11
;    IDL> print, stx_ltpair_assignment( [2,1,11])
;           1       2       5
;    IDL> print, stx_ltpair_assignment(lindgen(32)+1, /adgroup_idx)
;          2       2       8       8       1       3       3       7       7       5       1       4       4       6       6       5      13      14
;          14      12      12       9      13      15      15      11      11       9      16      16      10      10
;    
;    IDL> print, stx_ltpair_assignment(/PAIRS)
;          11       5
;           1       2
;           7       6
;          13      12
;          16      10
;          15      14
;           9       8
;           3       4
;          22      28
;          32      31
;          27      26
;          20      21
;          17      23
;          18      19
;          25      24
;          29      30
; :history:
;     29-apr-2013, Richard Schwartz, from graphic distributed by Gordon Hurford 
;     11-mar-2014, Nicky Hochmuth, add the ADGROUP_IDX keyword     
;     18-apr-2014, Richard Schwartz, added default for isc_in, lindgen(32)+1
;     15-apr-2015, Richard Schwartz, revised to use stx_adg_sc_table.pro
;     27-apr-2015, Richard Schwartz, restored old behavior for isc_in input with /adg_idx
;       keyword.  Returns adg_idx for each isc_in input
;-
function stx_ltpair_assignment, isc_in, $
  PAIRS=PAIRS, ADGROUP_IDX=ADGROUP_IDX, ERROR = ERROR

adg = stx_adg_sc_table()
adg_sc = adg[sort( adg.sc )]
adg_adg = adg[ sort( adg.adg_idx ) ]

default, isc_in, lindgen(32)+1
if keyword_set( pairs ) then begin
  ;Pairs of SC detector numbers ordered by AD group
  pairs = (reform( adg_adg[1:*], 2, 16 )).sc
  return, pairs
  endif
  
mm = minmax( isc_in )
if mm[0] lt 1 or mm[1] gt 32 then begin ;throw an error
  error = 1
  message,/info,'STIX subcollimator out of range. Must be from 1-32'
  return, -1
  endif

if keyword_set(ADGROUP_IDX) and n_elements( isc_in ) eq 0 then begin ;print the adgroup in sc order
  adgroup = adg_sc[1:*].adg_idx
  return, adgroup
endif else return, adg_sc[ isc_in ].adg_idx
 
 error = 0
 
  return, adg_sc[ isc_in ]. sc_twin
 end