function stx_sim_event_trigger
  ; initialize every event trigger with relative time -1 whith means it has not been initialized
  trigger = { stx_sim_event_trigger}
  trigger.relative_time = -1
  return, trigger
end