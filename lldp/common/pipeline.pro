; Requests are "request_YYMMDD_HHMMSS_AnyName
;
FUNCTION request_search_pattern
  nnnnnn = "[0-9][0-9][0-9][0-9][0-9][0-9]"
  
  return, "request_" + nnnnnn + "_" + nnnnnn + "_*"
END 


FUNCTION find_request, request_dir, failed_dir, products_dir, tmp_dir
  request_search = request_dir+"/"+request_search_pattern()

  print, "Searching... ", format='(A,$)'
  requests = file_search(request_search, count=count)

  print, trim(count)+" requests found"
  print

  IF count EQ 0 THEN return, ""
  
  requests=file_basename(requests)

  ; Ok, check if we've tried/succeeded/failed already:
  FOR i=0, n_elements(requests)-1 DO BEGIN
     request=requests[i]
     print,request+"... ", format='(A,$)'

     ; Failed?
     IF file_search(failed_dir+"/"+request) THEN BEGIN
        print, "found in FAILED directory"
        CONTINUE
     END

     IF file_search(tmp_dir+"/"+request) THEN BEGIN
        print, "found in TEMPORARY directory"
        print, "- UNDER PROCESSING or FAILED????"
        CONTINUE
     END

     ; Successfully done?
     IF file_search(products_dir+"/"+request) THEN BEGIN
        print, "completed (in main output)"
        CONTINUE
     END

     ; We didn't find it anywhere - go do it!
     print, "to be processed!"
     return, request
  END
END

PRO pipeline, interactive = interactive
  interactive = keyword_set(interactive)
  
  print, "IDL pipeline procedure started"
  
  lm_license_file = getenv("LM_LICENSE_FILE")
  print, "LM_LICENSE_FILE: "+lm_license_file

  requests_dir=getenv("instr_input_requests")
  IF requests_dir EQ "" THEN $
     message, "instr_input_requests not set, can't continue"

  instr_output=getenv("instr_output")
  IF instr_output EQ "" THEN $
     message, "instr_output not set, can't continue"
  
  products_dir = instr_output+'/products'
  file_mkdir, products_dir
  
  failed_dir=instr_output+"/failed"
  file_mkdir, failed_dir

  ; We will hide output directories under a tmp dir to easily move
  ; everything to failed or to plain products_dir when
  ; finished/crashed

  tmp_dir=instr_output+"/temporary"
  file_mkdir, tmp_dir

  print, "Main loop starting -------------------------------------"
  print
  
  sym = ['-----------','***********']
  i = 0
  WHILE 1 DO BEGIN
     ; To make it easier to see if the the program is still running, use
     ; alternating - or * when building up the following output string
     i = (i) ? 0 : 1
     reqstr = sym[i] + ' Looking for new requests '+ sym[i] 
            
     print
     print, reqstr 
     
     ; Nothing is currently being processed:
     ;
     request=""
     
     ; Failing is normally signalled by throwing a MESSAGE, but in
     ; interactive use, this manual flag may be set prior to returning here
     ; in order to trigger a normal fail response using a GOTO statement.
     ;
     fail_signal = 0
     
     ; Error handling, triggered by CATCH, except when called interactively
     ;
     err=0
     IF NOT interactive THEN catch, err
     
     ; Cancel CATCH, print error message, sanity check (errors when not
     ; actually processing anything?), say what's happening next, move
     ; temporary output directory to fail directory. Move on (CONTINUE).
     ;
     IF err NE 0 THEN BEGIN
        
        ; FAIL signalling is only for interactive use (no CATCH in effect) so
        ; that failures can be tested
        ; 
        FAIL_SIGNALLED:
        catch, /cancel
        print, !error_state.msg
        
        IF request EQ "" THEN $
           message, "Hey, I crashed without processing anything???"
        
        message, /continue, request+" failed, moving it to fail directory"
        
        file_move, current_tmp_product_dir, failed_dir
        print
        
        CONTINUE
     END

     request = find_request(requests_dir, failed_dir, products_dir, tmp_dir)
     IF request NE "" THEN BEGIN
        current_request_dir = requests_dir+"/"+request
        
        ; Create temp output directory for atomic move to main directory or
        ; fail directory
        ; 
        current_tmp_product_dir = tmp_dir+"/"+request
        file_mkdir, current_tmp_product_dir
 
        ; Filenames containing test_marker should have static file names
        ; (possibly derived from request name)
        ;
        test_marker = "test"
        IF strpos(request, test_marker) GT -1 THEN test = 1
           
        ; Kick off processing. Note that procedure name is now generic - the
        ; IDL_PATH should be set such that it picks up the right one (see
        ; common/idl_startup.pro).
        ;
        process_request, current_request_dir, current_tmp_product_dir
        
        ; Success! 
        ;
        file_move, current_tmp_product_dir, products_dir
     END

     ; We're done with a request. Or not. Anyhow, there's not
     ; supposed to be any temporary directory to move anywhere (fail
     ; or no fail).

     current_request_dir=""
     
     sleep_time = 5 ; Seconds
     print, "Sleeping "+trim(sleep_time)+" sec...", format = '(A,$)'
     wait, sleep_time
     print
  END 

END
