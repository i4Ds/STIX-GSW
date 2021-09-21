FUNCTION hsi_select_box,image,separation=separation,list=list,nop=nop

;image must be n*n!!!


;op=plotman(input=image, plot_type='image', colortable=5 )
op=plotman(input=image, plot_type='image',colortable=5)
op->set,colortable=5
bb=op->mark_box(list=list,nop=nop)

dim=[n_elements(image(*,0)),n_elements(image(0,*))]
nbox=n_elements(bb.nop)

if bb.nop(0) ne 0 then begin 

nperbox=bb.nop

for i = 0,nbox-1 do begin
    xind=bb.list( 0, total(nperbox(0:i))-nperbox(i):total(nperbox(0:i))-1 )
    yind=bb.list( 1, total(nperbox(0:i))-nperbox(i):total(nperbox(0:i))-1 )
    box=lonarr(2,n_elements(xind))
    box(0,*)=xind
    box(1,*)=yind
    ;round on or off so that size of clean box is maximized.  pollyfillv won't activate a box
    ; unless center lies to right of boundary
    abox = [avg(box(0,*)),avg(box(1,*))]
    for n = 0,1 do for j = 0,n_elements(box(n,*))-1 do $
                if (box(n,j)-abox(n)) gt 0 then box(n,j) = fix(box(n,j)+1) else box(n,j) = fix(box(n,j))

    list = polyfillv(box(0,*),box(1,*),dim[0], dim[1])
    ;im(list)=0
    if i eq 0 then inside=list else inside=[inside,list]
    if i eq 0 then separation=n_elements(list) else separation=[separation,n_elements(list)]
endfor

list=bb.list
nop=bb.nop

obj_destroy,op

return,inside

endif else begin   ;no box selected
obj_destroy,op
inside=-1 
return,inside

endelse


END