;+
;Name: STX_help_doc
;
;Purpose: This procedure finds the procedure and displays all document header
;
;History:
;   14-oct-2013, richard.schwartz@nasa.gov, doc_menu should be used but that is
;   hopelessly antiquated at this time
;-
pro stx_help_doc, proc_name
chkarg,proc_name, proc
s=where(strmid(proc,0,1) eq  ';', ns)
zstop = where( strmid( proc[s], 0, 1)  eq ';-', nstop)
if nstop ge 1 then s=s[0: last_item( zstop)]
 
if ns ge 1 then more, proc[s]
end