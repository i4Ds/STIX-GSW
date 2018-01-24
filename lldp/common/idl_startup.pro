;; IDL startup (private)

; Add instrument-specific IDL subdir

instr = strlowcase(getenv("INSTR"))
add_path, "$HOME/svn/idl/"+instr, /expand

;; This is executed as the very last statements of the SSW IDL startup
;; sequence. Delete the annoying ssw_idl.*** files littering the
;; homedir!

idl_startup =  getenv("IDL_STARTUP")
ssw_startup =  stregex(idl_startup,'ssw_idl.[0-9 ]+$',/boolean)

IF ssw_startup THEN print,""
IF ssw_startup THEN print,"DELETING SSW IDL STARTUP: "+idl_startup
IF ssw_startup THEN file_delete,idl_startup
