# ============================================================================
# Audio
# PipeWire with ALSA, PulseAudio compatibility, and realtime priorities.
# ============================================================================
_: {
  den.aspects.audio.nixos = {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Give PipeWire realtime scheduling without running it as root.
    security.rtkit.enable = true;
  };
}
