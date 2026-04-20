# User-level impermanence (Linux only) - persist directories under ~/.
# Reads `osConfig.nixfleet.impermanence.{enable,persistRoot}` from the
# NixOS-side impermanence scope.
{
  lib,
  osConfig,
  ...
}: let
  cfg = osConfig.nixfleet.impermanence or {enable = false;};
in {
  config = lib.mkIf cfg.enable {
    home.persistence.${cfg.persistRoot} = {
      hideMounts = true;
      directories = [
        # Keys (agenix-managed, not .ssh or .gnupg - those are ephemeral)
        ".keys"

        # Source code
        ".local/share/src"

        # Shell
        ".zplug"
        ".local/share/zsh"

        # GitHub CLI
        ".config/gh"

        # Neovim
        ".local/share/nvim"
        ".cache/nvim"

        # Tmux resurrect sessions
        ".cache/tmux"

        # Zoxide
        ".local/share/zoxide"

        # Nix state
        ".local/share/nix"
      ];
      files = [
        ".ssh/known_hosts"
      ];
    };
  };
}
