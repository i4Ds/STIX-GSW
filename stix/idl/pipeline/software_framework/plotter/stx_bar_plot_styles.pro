function stx_bar_plot_styles, default_styles=default_styles, health_styles=health_styles
  ; Set the default values
  default_values = { $
    dimensions: [500,500], $
    position: [0.1,0.88,0.9,0.9], $
    styles: ['green'], $
    axis_style: 0, $
    name_prefix: 'bar', $
    ytitle: 'Energy', $
    names: ['STIX Plot 1'], $
    fill_level: 0, $
    linestyle: ' ' $
  }
  
  ; Set the detector health plot styles
  health_values = { $
    dimensions: [500,500], $
    plot_position: [[0.05,0.1055,0.8,0.1255],[0.05,0.131,0.8,0.151],[0.05,0.1565,0.8,0.1765],[0.05,0.182,0.8,0.202],[0.05,0.2075,0.8,0.2275],[0.05,0.233,0.8,0.253], $
                [0.05,0.2585,0.8,0.2785],[0.05,0.284,0.8,0.304],[0.05,0.3095,0.8,0.3295],[0.05,0.335,0.8,0.355],[0.05,0.3605,0.8,0.3805],[0.05,0.386,0.8,0.406], $
                [0.05,0.4115,0.8,0.4315],[0.05,0.437,0.8,0.457],[0.05,0.4625,0.8,0.4825],[0.05,0.488,0.8,0.508],[0.05,0.5135,0.8,0.5335],[0.05,0.539,0.8,0.559], $
                [0.05,0.5645,0.8,0.5845],[0.05,0.59,0.8,0.61],[0.05,0.6155,0.8,0.6355],[0.05,0.641,0.8,0.661],[0.05,0.6665,0.8,0.6865],[0.05,0.692,0.8,0.712], $
                [0.05,0.7175,0.8,0.7375],[0.05,0.743,0.8,0.763],[0.05,0.7685,0.8,0.7885],[0.05,0.794,0.8,0.814],[0.05,0.8195,0.8,0.8395],[0.05,0.845,0.8,0.865], $
                [0.05,0.8705,0.8,0.8905],[0.05,0.896,0.8,0.916],[0.05,0.9215,0.8,0.9415]], $
    base_position: [0.05,0.1,0.8,0.95], $
    styles: ['green','yellow','red','black'], $
    axis_style: 0, $
    name_prefix: 'bar', $
    ytitle: 'Detectors', $
    names: ['1a','1b','1c','2a','2b','2c','3a','3b','3c','4a','4b','4c','5a','5b','5c','6a','6b','6c','7a','7b','7c','8a','8b','8c','9a','9b','9c','10a','10b','10c','cfl','bkg','flare'], $
    fill_level: 0, $
    linestyle: ' ', $
    showxlabels: 1 $
  }

  if keyword_set(default_styles) then return, default_values
  if keyword_set(health_styles) then return, health_values
  
  return, 0
end