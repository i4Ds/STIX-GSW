;+
; :description
;    This procedure provides a timed and calibrated event list with the science enegy bin
;
; :categories:
;   STIX flight software simulator
;
; :params:
;   science_channel_conversion_table_file - just what it says
;
; :example:
;   science_channels = stx_fsw_get_science_channels() 
;   
; :returns:
;   default science energy channels
;
; :history:
;   21-apr-2014 - rschwartz70@gmail.com, initial release, this is a temporary method
;   although it could easily be incorporated in the mail object path

;-

function stx_fsw_get_science_channels, science_channel_conversion_table_file
default, science_channel_conversion_table_file, concat_dir(getenv('STX_DET'), 'stx_ad_science_channels.txt')

a = rd_tfile( science_channel_conversion_table_file, hskip=3, /auto, /conver)
scc = reform( a[2:*,*], 33, 12, 32 ) ; channel, pixel, detector
;if you want to change the order of the indices (why, I don't know it makes sense this way
r_scc = intarr( 32, 12, 33 )
for ii = 0, 31 do for jj = 0, 11 do r_scc[ ii, jj, * ] = scc[ *, jj, ii]
scc = r_scc
return, scc
end