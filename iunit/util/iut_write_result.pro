pro iut_write_result, reports, filename, format
  
  reports_to_export = reports[where(reports.class ne '')]
  
  case (strlowcase(format)) of
    "xml": begin
       
       n_tests = n_elements(reports) 
       
       oXML = OBJ_NEW('IDLffXMLDOMDocument') 
       testsuite  = oXML->CreateElement('testsuite')
       testsuite ->SetAttribute, 'name', 'alltests'
       testsuite ->SetAttribute, 'tests', trim(n_tests)
       testsuite ->SetAttribute, 'errors', trim(n_elements(where(reports.result eq 0))) 
       testsuite ->SetAttribute, 'time', trim(total(reports.duration))
       testsuite ->SetAttribute, 'timestamp', '1'
       
       for i=0l, n_tests-1 do begin
        
        report=reports[i]
        
        testcase = oXML->CreateElement('testcase')
        
        testcase ->SetAttribute, 'name', report.method
        testcase ->SetAttribute, 'classname', report.class 
        testcase ->SetAttribute, 'time', trim(report.duration)
        
        if ~report.result then begin
          error = oXML->CreateElement('error')
          error ->SetAttribute, 'type', "Assertation Error"
          stack_trace = oXML->createtextnode(report.stack_trace)
          oVoid = error->AppendChild(stack_trace)
          oVoid = testcase->AppendChild(error)
        end
                
        
        
        oVoid = testsuite->AppendChild(testcase)
       endfor
       
       oVoid = oXML->AppendChild(testsuite) 
       oXML->Save, FILENAME=filename, /pretty_print
     
      
    end
    else: begin
      ;default is csv format
      reports_to_export.stack_trace = str_replace(reports_to_export.stack_trace,STRING(13B),"<nl />")
      reports_to_export.stack_trace = str_replace(reports_to_export.stack_trace,STRING(11B),"<tab />")
  
      WRITE_CSV, filename, $ 
        reports_to_export.class,  $
        reports_to_export.method,  $
        reports_to_export.result, $
        reports_to_export.error_msg, $
        reports_to_export.stack_trace, $
        reports_to_export.duration, $
        header=["class","method","result","error_msg","stack_trace","duration"]
    end
  endcase
  
end