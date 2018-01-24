pro STX_Timer::test
  compile_opt static

  o = Stx_Timer()
  o->startTimer, 1, /infinit
  p = plot(/test)
  for i=10L, 800L do p->setData, RANDOMU( seed, i)
  o->stopTimer
end

PRO STX_Timer::handleTimerEvent, id, userData

  COMPILE_OPT IDL2

  PRINT, 'STX_Timer::handleTimerEvent( ', STRing(id), userData, ' )'
  
  if isa(userData, /NUMBER) && userData gt 0 && ~self._stop then void = Timer.Set( userData, self, userData )
END

pro STX_TIMER::startTimer, time, infinit=infinit
  id = Timer.Set(time, self, (KEYWORD_SET(infinit) ? time : 0))
end

PRO STX_Timer::stopTimer
  self._stop = 1b
end

PRO STX_Timer__define

  COMPILE_OPT IDL2

  !null = { STX_Timer, $
    _stop : 0b, $
    INHERITS IDL_Object $

  }

END

