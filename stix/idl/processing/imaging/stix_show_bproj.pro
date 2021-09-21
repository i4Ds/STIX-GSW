PRO stix_show_bproj,this_vis,imsize=imsize,pixel=pixel,out=out,scaled_out=scaled_out


; calucates bprojection maps for each subcollimator and plots result on screen
; input visiblities
; Sep 2021: works for sc 3-10
; stix_show_bproj,this_vis

subc_index = stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c','6a','6b','6c',$
                             '5a','5b','5c','4a','4b','4c','3a','3b','3c'])
if ~ARRAY_EQUAL(subc_index, stix_label2ind(this_vis.label)) then message, 'Use all detectors from 10 to 3 (ordered as 10a, 10b, 10c, 9a,..)'

;number of visibilites
vdim=n_elements(this_vis)

if not keyword_set(imsize) then imsize=[512.,512.]*2.
if not keyword_set(pixel) then pixel=[1.,1.]

;make bprojection for each
for i=0,vdim-1 do begin
  this_bmap=bproj_stix_sep2021(this_vis[i],imsize,pixel,silent=silent)
  if i eq 0 then sbmap=this_bmap else sbmap=[sbmap,this_bmap]
endfor

;set bottom left corner to max in a,b, and c for display
sbmap0=sbmap
for i=0,vdim/3-1 do begin 
  this_max=max(sbmap0(3*i:(i+1)*3-1).data)
  sbmap0(3*i:(i+1)*3-1).data[0,0]=this_max
endfor
;set corner to max overall
sbmap0.data[0,0]=max(sbmap.data)

;make bproj for coarsed 3, then add next 3 
;nat and uni
for i=0,vdim/3-1 do begin
  this_bmap=bproj_stix_sep2021(this_vis[0:(i+1)*3-1],imsize,pixel,silent=silent)
  if i eq 0 then bmap_nat=this_bmap else bmap_nat=[bmap_nat,this_bmap]
  ;same for uni
  this_bmap=bproj_stix_sep2021(this_vis[0:(i+1)*3-1],imsize,pixel,silent=silent,/uni)
  if i eq 0 then bmap_uni=this_bmap else bmap_uni=[bmap_uni,this_bmap]
endfor


;add summed after each set, ie. order is sc a,sc b,sc c,averaged(abc), 
sbmap_plus=replicate(sbmap[0],vdim/3*4)
out=replicate(sbmap[0],vdim/3*4)
for i=0,vdim/3-1 do begin
  this_sum=sbmap[i*3]
  this_sum.data=average(sbmap[i*3:(i+1)*3-1].data,3)
  sbmap_plus[i*4:(i+1)*4-2]=sbmap0[i*3:(i+1)*3-1]
  sbmap_plus[(i+1)*4-1]=this_sum
  out[i*4:(i+1)*4-2]=sbmap[i*3:(i+1)*3-1]
  out[(i+1)*4-1]=this_sum
endfor

sbmap_plus.data[0,0]=max(sbmap_plus.data)

scaled_out=sbmap_plus

this_size=100
loadct,5
window,0,xsize=4*this_size,ysize=vdim/3*4*this_size
for i=0,vdim/3*4-1 do tvscl,congrid(sbmap_plus(i).data,this_size,this_size),i


;this_size=150
;window,2,xsize=vdim/3*this_size,ysize=this_size
;tvscl,congrid(sbmap_plus(3).data,this_size,this_size),0
;for i=1,vdim/3*4-1 do tvscl,congrid(average(sbmap_plus(indgen(i+1)*4+3).data,3),this_size,this_size),i

this_size=129
window,2,xsize=vdim/3*this_size,ysize=2*this_size
for i=0,vdim/3-1 do tvscl,congrid(bmap_nat(i).data,this_size,this_size),i
for i=0,vdim/3-1 do tvscl,congrid(bmap_uni(i).data,this_size,this_size),i+vdim/3.

END
