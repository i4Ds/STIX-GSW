;+
; :project:
;       STIX
;
; :name:
;      stx_plot_obj
;
; :purpose:
;       Object supporting reading and plotting of SITX fits files
;
; :categories:
;       pltotting, fits, io
;
; :keyword:
;
; :returns:
;       Fits header data as string array
;
; :examples:
;       
;
; :history:
;       06-Dec-2018 – SAM (TCD) init
;
;-

function stx_plot_obj::init
    compile_opt idl2
    
    return, 1
end

function stx_plot_obj::set_data, data
    compile_opt idl2
    
    self.stx_data = ptr_new(data)
end

function stx_plot_obj::get_data
    compile_opt idl2

    return, *self.stx_data
end

function stx_plot_obj::plot
    data = self->get_data()

    obs = data['count']
    energy = data['energy']
    
    xdata = obs.time
    
    ; Should probably either split on fileanme or tag, tags alone are not unique, lc and specta
    if have_tag(obs, 'background') then begin
        ydata = transpose(obs.background)
        plot_info = { $
            id: 'Ql Background', $
            data_unit: 'Counts', $
            plot_type: 'utplot' $
        }
    endif else if have_tag(obs, 'counts') then begin 
        n_dimms = size(obs.counts, /n_d)
        ; 2d lightcurve
        if n_dimms eq 2 then begin
            ydata = transpose(obs.counts)
            plot_info = { $
                id: 'Ql Lightcurve', $
                data_unit: 'Counts', $
                plot_type: 'utplot' $
            }
        ; 3d spectrogram
        endif else if n_dimms eq 3 then begin
            ydata = transpose(obs.counts)
            
            ;TODO Currently summing over detectors need to plot each and give option to sum 
            ydata = total(ydata, 2)
            plot_info = { $
                id: 'Ql Spectra', $
                data_unit: 'Energy', $
                plot_type: 'specplot' $
            }
        endif
    endif else if have_tag(obs, 'variance') then begin
        ydata = obs.variance
        plot_info = { $
            id: 'QL Variance', $
            data_unit: 'Counts', $
            plot_type: 'utplot' $
        }
    endif
    
    edge_products, reform([energy.e_min, energy.e_max], 2, n_elements(energy.e_min)), mean=mean_energy 
    
    plot_obj = obj_new(plot_info.plot_type, xdata, ydata) ;trim
    plot_obj->set, dim1_ids=trim(energy.e_min) + ' - ' + trim(energy.e_max) + 'keV', $
        data_unit = plot_info.data_unit, id=plot_info.id, dim1_vals=mean_energy
    
    ; Check if we have an plotman object if we do add panel if not create store
    if is_class(self.plotman_obj, 'PLOTMAN',/quiet) then begin
        self.plotman_obj->new_panel, desc=plot_info.id, /replace, input=plot_obj, $
            plot_type='utplot', _extra=extra
    endif else begin
        plot_obj->plotman, plotman_obj=plotman_obj
        self.plotman_obj = plotman_obj
    endelse
        
end

function stx_plot_obj::read, filepath
    reader_obj = fitsread(filename=filepath)

    obs_data = reader_obj->getdata(extension='rate')
    energy_data = reader_obj->getdata(extension='eneband')
    
    self.stx_data = ptr_new(DICTIONARY('count', obs_data, $
                                       'energy', energy_data)) 
end

pro stx_plot_obj__define
    compile_opt idl2

    define = {stx_plot_obj, $
        stx_data: ptr_new(), $
        plotman_obj: obj_new() $
    }
end