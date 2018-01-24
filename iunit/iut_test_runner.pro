pro iut_test_runner_event, ev
  common iut_test_runner, status
  
  widget_control, ev.id, get_uvalue=uvalue
  
  checkvar, uvalue, "resize"
  
  case uvalue of
    'resize'    : begin
      Widget_Control, status.text,  SCR_XSize=ev.x, SCR_YSize=ev.y*0.3
      Widget_Control, status.table, SCR_XSize=ev.x, SCR_YSize=ev.y*0.7, COLUMN_WIDTHS=(ev.x-100) * [0.4,0.05,0.1,1]
      
    end
    'table'    : begin
      print, status.reports[ev.SEL_TOP]
      
      showtext = (status.reports[ev.SEL_TOP]).stack_trace
      widget_control,status.text,set_value=str2arr(showtext,STRING(13B))
    end
  endcase
  
  
end

; :history:
;   15-Jul-2015 - Laszlo I. Etesi (FHNW), added option setting a search root and exclude patters (either an array of strings or a comma separated string of patterns)
;   16-Jul-2015 - Laszlo I. Etesi (FHNW), - bugfix (crash when no excludes were given)
;                                         - allowing tc1 to be an undefined variable -> do auto-search
function iut_test_runner, tc1, tc2, tc3, tc4, tc5, tc6, tc7, tc8, tc9, tc10, search_root=search_root, exclude=exclude, stoponerror=stoponerror, gui=gui, debug=debug, csv_filename=csv_filename, format=format, reports=reports, _extra=extra
   common iut_test_runner, status
  default, format, "csv" 
  default, stoponerror, 0
  default, gui, 1
  default, debug, 0
  default, search_root, '*'
  default, exclude, ''
  testfiles = strarr(10)
  text = 0
  
  if n_params() eq 0 || ~isvalid(tc1) then begin
    class_pattern='__define.pro'    
    testfiles = file_search(search_root,'*__test'+class_pattern)
    testfiles = str_replace(testfiles,class_pattern)
    
    ; allow for exclusion of certain folders or tests
    if(exclude[0] ne '') then begin
      if(~isarray(exclude) && stregex(exclude, ',')) then exclude = trim(strsplit(exclude, ',', /extract))
      exclude_regex = arr2str(exclude, delim='|')
      exclude_idx = where(stregex(testfiles, exclude_regex, /bool), complement=include_idx)
    endif
    if(isvalid(include_idx)) then testfiles = testfiles[include_idx]
    testfiles = file_basename(testfiles)
  end else begin
    idx = 0
    for i=1, n_params() do begin
      filename = scope_varfetch('tc'+trim(i))
      if valid_class(filename) then  testfiles[idx++]=filename
    end
    testfiles = testfiles[0:idx-1]
  endelse
  
  if gui then begin
    
    base = widget_base(XSIZE=800, YSIZE=600, TITLE="IUnit - Testing", /COLUMN,/TLB_Size_Events)
    table = widget_table(base, COLUMN_WIDTHS=[200, 35, 65, 400], $
      XSIZE=4, ysize=1, SCR_XSIZE=800, SCR_YSIZE=400, uvalue="table", $
      SENSITIVE=1,column_labels=["Name","Status","Time","Error"],/scroll,/all_events)
      
    widget_control, table, SET_TABLE_VIEW=[0, 0]
    widget_control, table, SET_TABLE_SELECT=[0, 0, 0, 0]
    
    text = widget_text(base, SCR_XSIZE=800, SCR_YSIZE=180,/scroll,uvalue="text")
    
    widget_control, base, /REALIZE
    xmanager, 'iut_test_runner', base, /no_block
  end
  
  row=0
  
  
  report_idx = 0
  reports=replicate(iut_testresult("","",1,"",""),100000L)
  
  for i=0, n_elements(testfiles)-1 do begin
    testfile = testfiles[i]
    
    resolve_all, class=testfile, /continue_on_error, quiet=~debug
     
    if(~obj_isa(testfile, 'iut_test')) then continue

    if gui then begin
      if row ge 1 then widget_control, table, INSERT_ROWS=1
      widget_control, table, set_table_select=[0,row,3,row]
      widget_control, table, set_value=[testfile,"","",""], BACKGROUND_COLOR=[255, 255, 0],  /USE_TABLE_SELECT
      widget_control, table, SET_TABLE_VIEW=[0,0]
      
      widget_control, base, TLB_SET_TITLE="IUnit - Testing: "+testfile
    endif
    reports[report_idx++] = iut_testresult("","",1,"",text)
    
    row++
    
    if debug then print, testfile
    
    testclass=obj_new(testfile, _extra=extra)
  
    testcases = testclass->find_tests()
    
    if gui && n_elements(testcases) gt 0 then begin
      widget_control, table, INSERT_ROWS=n_elements(testcases)
      widget_control, table, set_table_select=[0,row,1,row+n_elements(testcases)-1]
      widget_control, table, SET_VALUE=[transpose(testfile+"::"+testcases),transpose(replicate("waiting",n_elements(testcases)))],  /USE_TABLE_SELECT
      widget_control, table, SET_TABLE_VIEW=[0,0]
    endif
    result = []
    skipAfterBefore = 0b
    
    for t=0, n_elements(testcases)-1 do begin
      testcase = testcases[t]
      
      if gui then begin
        widget_control, table, set_table_select=[1,row,3,row]
        widget_control, table, SET_VALUE=["running"], /USE_TABLE_SELECT,background_color=[255,200,200]
        widget_control, table, SET_TABLE_VIEW=[0,0]
      end
      
      result = testclass->run_test(testcase,skip=skipAfterBefore,stoponerror=stoponerror)
  
      reports[report_idx++] = result
      
      if t eq 0 && result.result eq 0 then skipAfterBefore=1b
      
      if gui then begin
        widget_control, table, set_table_select=[1,row,3,row]
        widget_control, table, SET_VALUE=[result.result?"OK":"FAIL",trim(result.duration),result.error_msg], /USE_TABLE_SELECT,background_color=result.result?[0,255,0]:[255,0,0]
        widget_control, table, SET_TABLE_VIEW=[0,0]
        widget_control, table, set_table_select=[0,0,0,0]
      end
      
      row++
      
      if debug then print,result
      if ~result.result && stoponerror then break
      
    end
      if exist(result) && ~result.result && stoponerror then break
  end
  
  if ~exist(reports) then begin
    reports = iut_testresult("no testcase found")
    if gui then begin
      widget_control, table, set_table_select=[0,row,3,row]
      widget_control, table, set_value=["no class and test case found","ERROR",'0'], BACKGROUND_COLOR=[255, 255, 0],  /USE_TABLE_SELECT
    end
  end else begin
    reports=reports[0:report_idx-1]
  end
  
  if gui then status = {$
    reports : reports, $
    text    : text, $
    table   : table $
  }
  
  success = n_elements(reports) gt 0 && total(reports.result) eq n_elements(reports)
  
  if gui then widget_control, base, TLB_SET_TITLE = "IUnit - "+(success ? "APPROVED": "FAILURE")
  
  if keyword_set(csv_filename) then iut_write_result, reports, csv_filename, format 
  
  return,  success
end