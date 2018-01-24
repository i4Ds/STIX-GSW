;+
; :description:
;    This is a test routine used when reading XML configuration data. It
;    extracts the text value from a text node.
;
; :categories:
;    xml, configuration, utility
;
; :params:
;    node : in, required, type='idlffxmldomelement'
;      the node text node
;      
; :returns:
;    the text content of the text node; if no node was found !NULL is returned
;
; :examples:
;    text = ppl_xml_get_single_text_value(node)
;
; :history:
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;    27-Aug-2014 - Laszlo I. Etesi (FHNW), doing proper GC cleanup
;-
function ppl_xml_get_text_value, node
  ret_value = !NULL
  if(ppl_typeof(node, compareto='idlffxmldomelement')) then begin
    text_nodes = node->getchildnodes()
    if(text_nodes->getlength() gt 0) then begin
      text_node =  text_nodes->item(0)
      ret_value = text_node->getnodevalue()
      ;destroy, text_nodes
      ;destroy, text_node
    end
  endif
  return, ret_value
end