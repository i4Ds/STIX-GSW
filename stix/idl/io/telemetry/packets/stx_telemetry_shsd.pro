function stx_telemetry_shsd
  
  void = { $
    type                : "stx_telemetry_shsd" ,$
    DeltaTimeSeconds    : uint(0) ,$
    DeltaTimeSubSeconds : uint(0) ,$
    RateControlRegime   : byte(0) ,$
    NumberSubStructures : uint(0) ,$
    PixelMask           : bytarr(12) ,$
    DetectorsMask       : bytarr(32) ,$
    CoarseFlareLocation : bytarr(2) ,$
    LiveTimeAccumulator : uintarr(16), $
    ssid                : 10 $
  }
  
  return, void
  
end