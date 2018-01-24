FUNCTION simple_xml:: init
  message,"Initing",/info
  self.path_list = list()
  retval = self->IDLffXMLSAX::init()
  IF retval EQ 0 THEN print, "IDLffXMLSAX::init returned "+trim(retval)
  return,retval
END

PRO simple_xml::cleanup
  message,"Cleaning up",/info
  self->IDLffXMLSAX::cleanup
END


;; OVERRIDE--------------------------------------------------------------------
;;
;; HandleLeafElementData and *possibly* HandlePathClosure should be overridden
;; in order to make use of this object


;; HandleLeafElementData is called whenever the data inside a leaf element are
;; ready to be processed, upon reaching the end of the element - with the
;; complete data inside the leaf element
;;
;;
PRO simple_xml::HandleLeafElementData,data,elementName,elementPath
  self->HandleAny,data,elementName,elementPath
END 


;; HandlePathClosure is called at the end of a non-leaf element
;;
;;
PRO simple_xml::HandlePathClosure,elementName,elementPath
  self->HandleAny,"",elementName,elementPath
END

;; END OVERRIDE----------------------------------------------------------------



pro simple_xml:: StartDocument

END 



PRO simple_xml:: StartElement,uri,local,qname,attrnames,attrvalues
  IF local NE qname THEN message,qname+' != '+local,/info
  self.path_list->add,local
;  IF local EQ self.last_element THEN print,'-' ; Repeated descent
  self.last_element = ''
  self.data = ''
  self.open = 1
END


pro simple_xml:: Characters,data
  clean_data = self->CleanString(data)
  IF clean_data EQ '' THEN return
  IF self.data GT '' THEN self.data += ' '
  self.data = self.data + clean_data
END 


; This is the "generic" way to handle both leaf element and path closure data.
;
;
PRO simple_xml::HandleAny,data,elementName,elementPath
  
  IF self.open THEN print,elementPath + " = " + data
  
END


pro simple_xml:: EndElement,uri,local,qname
  IF local NE qname THEN message,qname+' != '+local,/info
  
  CASE self.open OF 
     1: self->HandleLeafElementData, self.data,local,self->path()
     0: self->HandlePathClosure, local, self->path()
  END
  
  ;; Book-keeping:
  ;;
  self.open = 0
  last_element_name_ix = self.path_list->count()-1
  self.last_element = self.path_list[last_element_name_ix]
  self.path_list->remove,last_element_name_ix
  
END 


pro simple_xml:: EndDocument
  
END 


; Indentation string for current self.level
;
FUNCTION simple_xml:: indent
  indent = ''
  FOR i=1,self.level DO indent += '   '
  return,indent
END


; Print indentation string for current self.level, no newline
PRO simple_xml:: indent
  print,self->indent(),format='(a,$)'
END 

; Return current path
FUNCTION simple_xml:: path
  return,strjoin(self.path_list->ToArray(),'.')
END

FUNCTION simple_xml:: CleanString,in_string
  
  remaining = in_string
  
  new_string = ''
  
  ;; Separator is used when adding new substring to new_string. No separator
  ;; for first substring (i.e. no leading space), but separator is then set to
  ;; a blank space for the next round
  ;;
  separator = ''
  
  REPEAT begin
     
     ;; We want all printable (non-control, non-space) characters:
     
     match_position = stregex(remaining,'[!-~]+',length=length)
     
     IF match_position GE 0 THEN BEGIN
        
        match_substring = strmid(remaining,match_position,length)
        
        new_string += separator + match_substring
        
        remaining = strmid(remaining,match_position+length)
        
        separator = ' '
     END 
     
  END UNTIL strlen(remaining) EQ 0 OR match_position EQ -1

  return,new_string
END 


;;;;;pro simple_xml::StartPrefixmapping
;;;;;  message,"here",/info
;;;;;END 

;;;;;pro simple_xml::EndPrefixMapping
;;;;;  message,"here",/info
;;;;;END 

pro simple_xml:: AttributeDecl
  message,"here",/info
END 

pro simple_xml:: Comment
  message,"here",/info
END 

pro simple_xml:: ElementDecl
  message,"here",/info
END 

pro simple_xml:: EndCDATA
  message,"here",/info
END 

pro simple_xml:: EndDTD
  message,"here",/info
END 

pro simple_xml:: EndEntity
  message,"here",/info
END 

pro simple_xml:: Error
  message,"here",/info
END 

pro simple_xml:: ExternalEntityDecl
  message,"here",/info
END 

pro simple_xml:: FatalError
  message,"here",/info
END 

pro simple_xml:: IgnorableWhitespace
  message,"here",/info
END 

pro simple_xml:: InternalEntityDecl
  message,"here",/info
END 

pro simple_xml:: NotationDecl
  message,"here",/info
END 

pro simple_xml:: ProcessingInstruction
  message,"here",/info
END 

pro simple_xml:: SkippedEntity
  message,"here",/info
END 

pro simple_xml:: StartCDATA
  message,"here",/info
END 

pro simple_xml:: StartDTD
  message,"here",/info
END 

pro simple_xml:: StartEntity
  message,"here",/info
END 

pro simple_xml:: StopParsing
  message,"here",/info
END 

pro simple_xml:: UnparsedEntityDecl
  message,"here",/info
END 

pro simple_xml:: Warning
  message,"here",/info
END 

PRO simple_xml__define
  patcher = {simple_xml,           $
                                   $
             inherits IDLffXMLSAX, $
                                   $
             path_list:list(),     $
             last_element:'',      $
             open:0,               $
             data:""               $
            }
END
