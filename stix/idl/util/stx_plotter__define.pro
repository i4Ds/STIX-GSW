function stx_plotter::init
    compile_opt idl2
    
    return, 1
end

function stx_plotter::set_data, data
    compile_opt idl2
    
    self.stx_data = ptr_new(data)
end

function stx_plotter::get_data
    compile_opt idl2

    return, *self.stx_data
end

function stx_plotter::plot
    data = self->get_data()

    obs = data['count']
    energy = data['energy']
    
    xdata = obs.time
    if have_tag(obs, 'background') then begin
        ydata = transpose(obs.background)
        plot_info = { $
                id: 'Ql Background', $
                data_unit: 'Counts' $ 
            }
    endif else if have_tag(obs, 'counts') then begin
        ydata = transpose(obs.counts)
        plot_info = { $
            id: 'Ql Lightcurve', $
            data_unit: 'Counts' $
        }
    endif
    
    plot_obj = obj_new('utplot', xdata, ydata) ;trim
    plot_obj->set, dim1_ids=string(energy.e_min) + ' - ' + string(energy.e_max), $
        data_unit = plot_info.data_unit, id=plot_info.id
    
    ; Check if we have an plotman object if we do add panel if not create store
    if is_class(self.plotman_obj, 'PLOTMAN',/quiet) then begin
        self.plotman_obj->new_panel, desc, /replace, input=plot_obj, $
            plot_type='utplot', _extra=extra
    endif else begin
        plot_obj->plotman, plotman_obj=plotman_obj
        self.plotman_obj = plotman_obj
    endelse
        
end

function stx_plotter::read, filepath
    reader_obj = fitsread(filename=filepath)

    obs_data = reader_obj->getdata(extension='rate')
    energy_data = reader_obj->getdata(extension='eneband')
    
    self.stx_data = ptr_new(DICTIONARY('count', obs_data, $
                                       'energy', energy_data)) 
end

pro stx_plotter__define
    compile_opt idl2

    define = {stx_plotter, $
        stx_data: ptr_new(), $
        plotman_obj: obj_new() $
    }
end