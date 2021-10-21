
function stx_uv_points_giordano

subc_str = stx_construct_subcollimator()

L1 = 550.
L2 = 47.

pitch_f = 1./subc_str.front.pitch * (L2 + L1) / 3600.0d / !RADEG
pitch_r = 1./subc_str.rear.pitch * L2 / 3600.0d / !RADEG

u = cos(subc_str.front.angle * !dtor) * pitch_f - cos(subc_str.rear.angle * !dtor) * pitch_r
v = sin(subc_str.front.angle * !dtor) * pitch_f - sin(subc_str.rear.angle * !dtor) * pitch_r

return, {u:u, v:v}

end