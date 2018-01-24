;+
; :description:
;    This procedure reads in the gain and offset and scince energy bin csv files
;    and writes out the ad to science energy channel conversion table for all pixels 
;    to a csv file
;
; :categories:
;    simulation
;
; :params:
; 
;    offset_gain_filename : in, required, type="string"
;                           the name of the csv file containing the gain and offset values for all pixels
;                                      
; :keywords:
;
;    filename             : in, type = "string", default ='sim_gain_offset_table'
;                           the name of the csv file to be written
;              
;    og_directory         : in, type = "string", default ='\stix\dbase\detector'
;                           the directory where the offset gain csv file is located
;                           
;    ad_directory         : in, type = "string", default ='\stix\dbase\detector'
;                           the directory where the ad to science energy csv file is to be written
;    
;    nocomma              : in,
;                           if set will write a text file without comma  
;                           
; :examples:
;    stx_science_energy_2_csv, 'offset_gain_table.csv', filename =  'ad_energy_table'
;
; :history:
;    30-jun-2015 - ECMD (Graz), initial release
;    03-jul-2015 - ECMD (Graz), change of default filename
;                               now using str2file for writing txt file
;
;-
pro stx_science_energy_2_csv, offset_gain_filename, filename = ad_energy_filename, directory_og = directory_og, directory_ad = directory_ad, nocomma = nocomma

default, directory_og, getenv('STX_DET')
default, directory_ad, getenv('STX_DET')
default, ad_energy_filename,'ad_energy_table'

science_bins = stx_science_energy_channels(/edges_1) ;energy science reader

og_str = stx_offset_gain_reader(offset_gain_filename, directory = directory_og )

nog = n_elements( og_str )
nsc = n_elements( science_bins )

ad_bins = round( transpose( reproduce( og_str.offset, nsc )) + $
          reproduce( science_bins, nog) / transpose( reproduce( og_str.gain, nsc ) ))
  
ad_table = [transpose(og_str.det_nr), transpose(og_str.pix_nr), ad_bins]

if keyword_set(nocomma)then begin
  txtfilename = ad_energy_filename + '.txt'
  full_txtfile = concat_dir( directory_ad, txtfilename)
  starr = reform(string(ad_table, format ='(I5)'),nsc+2,nog)
  strin =  strjoin(starr)
  str2file, strin, full_txtfile
endif else begin
  csvfilename = ad_energy_filename + '.csv'
  full_csvfile = concat_dir( directory_ad, csvfilename)
  write_csv, full_csvfile, ad_table
endelse

end