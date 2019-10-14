function stx_uniform_dstn,e, apar

e1 = get_uniq(e)
no_e = n_elements(e1)
e1 =reform(e1,no_e)
  y = fltarr(no_e)
  
  w = where(e1 ge apar[0] and e1 le apar[1])
  
  y[w] = 1
  
  y /= total(y)
  
  return, y
end