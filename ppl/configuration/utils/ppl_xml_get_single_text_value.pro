;+
; :description:
;    This is a test routine used when reading XML configuration data. It
;    allows to read exactly ONE text element that is a child of the given node.
;
; :categories:
;    xml, configuration, utility
;
; :params:
;    node : in, required, type='idlffxmldomelement'
;      the node to start looking for ONE text node
;      
;    name : in, required, type='string'
;      the name of the text node
;      
; :returns:
;    the text content of the text node; if no node was found !NULL is returned
;
; :examples:
;    text = ppl_xml_get_single_text_value(node, 'description')
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;    28-Aug-2014 - Laszlo I. Etesi (FHNW), doing proper GC cleanup
;-
function ppl_xml_get_single_text_value, node, name
  ret_value = !NULL
  if(ppl_typeof(node, compareto='idlffxmldomelement')) then begin
    text_nodes = node->getelementsbytagname(name)
    if(text_nodes->getlength() gt 0) then begin
      text_node = text_nodes->item(0)
      ret_value = ppl_xml_get_text_value(text_node)
      ;destroy, text_nodes
      ;destroy, text_node
    endif
  endif
  
  return, ret_value
end