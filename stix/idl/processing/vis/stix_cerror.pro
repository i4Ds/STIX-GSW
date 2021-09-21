FUNCTION stix_cerror,counts,skm=skm,perror=perror

  ; ==========================================================================
  ; Function computing the compression error for all counts in the array of
  ; counts using Gordon's tables.
  ; Parameters:
  ;     - counts      : array containing all counts (multidimensional array)
  ;     - skm         : COMPRESSION_SCHEME_COUNTS_SKM      BYTE      Array[3] 
  ; ==========================================================================



  ; Path to the Compression Error csv file
 if n_elements(where(skm-[0,5,3] eq 0)) eq 3 then path_CE_skm = loc_file( 'STIXdecomErrors_SKM053_Gordon_s.csv', path = getenv('STX_VIS_DEMO') )
 if n_elements(where(skm-[0,4,4] eq 0)) eq 3 then path_CE_skm = loc_file( 'STIXdecomErrors_SKM044_Gordon_s.csv', path = getenv('STX_VIS_DEMO') )

  ; Open and extract expected value and error
  data         = read_csv(path_CE_skm, header=header, table_header=tableheader)
  ;expect_cnts  = float(data.field09[9:-2])
  ;tot_rms_perc = float(data.field14[9:-2])
  expect_cnts  = float(data.field09)
  tot_rms_perc = float(data.field14)
  
  ;ce=float(data.field12[2:*])
  ;pe=float(data.field09[2:*])

  comp_error   = tot_rms_perc*expect_cnts/100.
  
  ;define error variable
  ecounts=counts*0.-1
  ;check maximum counts in input data
  max_counts=max(counts)
  ;list of relevant expect_cnts
  glist=where(expect_cnts le max_counts)
  gdim=n_elements(glist)
  ;loop over all elements in glist
  for i=0,gdim-1 do begin
     this_list=where( counts eq expect_cnts(i) )
     if this_list(0) ne -1 then ecounts(this_list)=comp_error(i)
  endfor
  if keyword_set(perror) then perror=sqrt(counts)
  
  return,ecounts
  
END
