;+
; :description:
;    This function takes a simulated pixel data structure and converts it to
;    the archive buffer format: [Detector, Energy, Pixel, Continuation Flag, Spare, [Counts]].
;    The format is not final. See https://stix.cs.technik.fhnw.ch/confluence/display/STX/STIX+Telemetry+Specification
;    This function does not change the order of the input data, i.e. the outputed archive buffer
;    data has the same detector, energy, and pixel "sorting".
;    
;    It is assumed that time and energy in pixel_data are indices and that energy are the 32 standard
;    energy bins. All indices start at 0 except the detector index which starts at 1 in the archive buffer
;    and is changed to 0 in the telemetry buffer
;    Skipping entries where counts = 0
;    Data is written "left to right"
;
; :categories:
;    simulation, converter, telemetry
;
; :params:
;    archive : in, required, type="stx_fsw_archive_buffer" ;named structure
;             The pixel data input contains  pixel data over
;             one time and multiple energies, detectors and pixels
;
; :returns:
;             a packed byte array ready for the telemetry stream writer
;
; :keywords:
;    NROWT - total number of rows(entries) of output whether 2 or 3 bytes per row
;
; :examples:
;    buffer = stx_archive_struct_to_teletry_buffer( archive )
;
; :history:
;    11-sep-2014 - richard.schwartz@nasa.gov
;    12-sep-2014 - richard.schwartz@nasa.gov - added NROWT keyword
;-
function stx_archive_struct_to_telemetry_buffer, archive, NROWT=nrowt

;  IDL> help, archive, /st
;  ** Structure STX_FSW_ARCHIVE_BUFFER, 5 tags, length=24, data length=23:
;     RELATIVE_TIME_RANGE
;                     DOUBLE    Array[2]
;     DETECTOR_INDEX  BYTE         8
;     PIXEL_INDEX     BYTE         7
;     ENERGY_SCIENCE_CHANNEL
;                     BYTE        16
;     COUNTS          ULONG                1;Count the number of rows needed for the telem buffer
nrowi  = ceil( archive.counts / 255.0 )
mrowi  = max( nrowi ) ;maximum number of rows for any single entry
nrowt  = total( nrowi, /integer )

;How many input structures? 
num_struct = n_elements(archive)

buffer = uintarr( nrowt ) ;where we're putting the detector, energy, and pixel bits
;make the mapping between the index into the archive rows and the telem_source_buffer
telem_index = long( ( [0, total( /cum, nrowi, /int )] )[ 0: num_struct - 1] )
sindex = lonarr( nrowt )
sindex[ telem_index ] = lindgen( num_struct ) ;pointer back to the archive buffer rows (input elements)

head =  ishft( uint( archive.detector_index - 1 ), 11 )   + $
        ishft( uint( archive.energy_science_channel ), 6 )   + $
        ishft( uint( archive.pixel_index ), 2 ) ; still must add the continuation bit
        
buffer[ telem_index ] = head ;fill the initial output buffer rows where the telem words start

counts = bytarr( nrowt  ) ;need a parking place for the counts we'll past onto the head later
counts[ telem_index ] = archive.counts < 255 ;fill the first entry for each word
;in this loop we fill all the empty rows with the head info and put in the counts residuals
if mrowi gt 1 then for jj = 1L, mrowi - 1 do begin
  q = where( counts[ jj:* ] eq 0 and counts eq 255, nq )
  diffjj = (long( archive[q].counts ) - (255*JJ)) < 255
  
  buffer[ q + jj ]  = buffer[ q - jj + 1 ]
  counts[ q + jj  ] = diffjj
  endfor
;Compute the continuation bit and remove any 1s from the count array
cbit  = where( counts gt 1, ncbit, comp = just_ones, ncomp = njust_ones )
if njust_ones ge 1 then counts[ just_ones ] = 0b
if ncbit ge 1 then buffer[ cbit ] += 2 ;set the cbit
;assemble the prelim output and finally make a bytestream array
out = bytarr( 3, nrowt )
buffer = byte( byteswap( buffer ), 0, 2, nrowt ) ;the integers are flipped in byteorder so byteswap
out[ 0:1, * ] = buffer
out[ 2, *   ] = counts

out = out[*]
;now remove the single count entry bytes from the bytestream array
if njust_ones ge 1 then remove, just_ones * 3 + 2, out
return, out
end

