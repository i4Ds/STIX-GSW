;+
; :description:
;     Event-handling routine for 'stx_sim_widget_plot_photons' widget
;
; :params:
;     event
;
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;-
pro stx_sim_widget_plot_photons_event, event
      widget_control, event.top, /destroy
end
