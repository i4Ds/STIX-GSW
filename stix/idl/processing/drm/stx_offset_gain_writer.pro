;+
; :description:
;    This procedure writes the gains and offsets for all pixels from a stx_offsetgain structure to a csv file
;
; :categories:
;    simulation
;
; :params:
; 
;    instr     : in, required, type="structure"
;               a stx_offsetgain structure containing the gain and offset values for all pixels
;             
; :keywords:
;
;    filename  : in, type = "string", default ='sim_gain_offset_table.csv'
;               the name of the csv file to be written
;              
;    directory : in, type = "string", default ='\stix\dbase\detector'
;               the directory where the offset gain csv file is located
;                           
; :examples:
;    stx_offset_gain_writer, ogstr, filename = 'offset_gain_table.csv'
;
; :history:
;    30-jun-2015 - ECMD (Graz), initial release
;    03-jul-2015 - ECMD (Graz), change of default filename
;     
;-
pro stx_offset_gain_writer, instr, filename = filename, directory = directory

default, directory , getenv('STX_DET')
default, filename, 'offset_gain_table.csv'

full_filename =  concat_dir( directory, filename) 

if ~ppl_typeof(instr, compareto = 'stx_offsetgain', /raw) then message, 'Input structure must be of type stx_offsetgain'

csvstr = { $
detector_number:instr.det_nr, $
pixel_number: instr.pix_nr, $
offset:instr.offset, $
gain:instr.gain $
}

header = ['detector_number','pixel_number','offset','gain']

write_csv, full_filename, csvstr, header = header

end