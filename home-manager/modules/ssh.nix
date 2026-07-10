{
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.ssh.enable = lib.mkEnableOption "SSH client configuration";

  config = lib.mkIf config.myconf.ssh.enable {
    programs.ssh = {
      enable = true;

      # Disable HM's deprecated default config block to avoid warnings.
      # We define our own equivalent defaults below using the new API.
      enableDefaultConfig = false;

      # Use the new `settings` API with upstream OpenSSH directive names.
      # The "*" block is the default Host block applied to all connections.
      settings."*" = {
        # Auto-add keys to the agent (gpg-agent with enableSshSupport on
        # desktop hosts, or ssh-agent on WSL) so passphrases are cached
        # after first use and not re-prompted.
        AddKeysToAgent = "yes";

        # Connection multiplexing — reuses a single TCP connection for
        # multiple SSH sessions to the same host. Reduces connection latency
        # for things like git push/pull over SSH.
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "10m";

        # Do NOT forward the agent globally — a compromised remote host could
        # use your keys. Enable per-host in matchBlocks if needed.
        ForwardAgent = false;

        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";

        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
      };
    };
  };
}

