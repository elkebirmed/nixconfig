# ============================================================================
# Koko User
# The koko account: identity plus the shared managed-user wiring.
# ============================================================================
{den, ...}: {
  den.aspects.koko = {
    user = {
      description = "Koko";

      # No SSH access; koko uses the desktop only.
      openssh.authorizedKeys.keys = [];
    };

    includes = [
      den.aspects.managed-user
      # Keyring, browser profile, and Noctalia state must survive rollbacks.
      den.aspects.persisted-state
      # Join Wi-Fi from the desktop without admin rights.
      den.aspects.koko-wifi
    ];
  };
}
