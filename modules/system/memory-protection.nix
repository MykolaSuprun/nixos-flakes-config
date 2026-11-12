_: {
  flake.modules.nixos.memory-protection = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myconf.nixos.memoryProtection;
    earlyoom = import ../../lib/earlyoom.nix {inherit pkgs;};
  in {
    options.myconf.nixos.memoryProtection = {
      enable = lib.mkEnableOption "memory-pressure protection for desktop compute workloads";
      modelServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Existing system model services sharing the compute memory budget.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = lib.all (name: config.systemd.services.${name}.serviceConfig ? ExecStart) cfg.modelServices;
          message = "memoryProtection.modelServices must name existing system services with an ExecStart.";
        }
      ];

      # Preserve the existing pressure policy for user scopes as well as the
      # new compute slice; otherwise they would fall back to upstream defaults.
      environment.etc."systemd/oomd.conf.d/10-memory-protection.conf".text = ''
        [OOM]
        DefaultMemoryPressureLimit=20%
        DefaultMemoryPressureDurationSec=20s
      '';

      services.earlyoom = {
        enable = true;
        inherit (earlyoom) package;
        # Delay graceful termination slightly, but force recovery with more
        # headroom than the old 10%/5% policy. Disk swap must not gate action.
        freeMemThreshold = 8;
        freeMemKillThreshold = 6;
        freeSwapThreshold = 100;
        freeSwapKillThreshold = 100;
        reportInterval = 15;
        extraArgs = ["--sort-by-rss" "--prefer" earlyoom.prefer "--avoid" earlyoom.avoid];
      };

      # Daemon-side workers need their own cgroups; a terminal scope cannot
      # account for builds that run as nixbld users under the system daemon.
      nix.settings = {
        extra-experimental-features = ["cgroups"];
        use-cgroups = true;
        max-jobs = 2;
        cores = 8;
      };

      systemd.slices.compute = {
        description = "Shared memory budget for model services and Nix builds";
        sliceConfig = {
          MemoryHigh = "75%";
          MemoryMax = "85%";
          MemorySwapMax = "16G";
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "20%";
          ManagedOOMMemoryPressureDurationSec = "20s";
        };
      };

      systemd.services = lib.mkMerge [
        {
          nix-daemon.serviceConfig = {
            Slice = "compute.slice";
            Delegate = true;
            # A failed build must not stop the daemon or its other builds.
            OOMPolicy = "continue";
            # Applies to the supervisor cgroup, not delegated build children.
            ManagedOOMPreference = "omit";
          };

          rss-watch = {
            description = "Memory pressure, zram and largest resident workloads";
            serviceConfig = {
              Type = "oneshot";
              TimeoutStartSec = "10s";
            };
            script = ''
              ${pkgs.procps}/bin/free -m | ${pkgs.coreutils}/bin/head -n 3
              ${pkgs.gawk}/bin/awk '{print "memory_psi " $0}' /proc/pressure/memory
              ${pkgs.gawk}/bin/awk '{print "io_psi " $0}' /proc/pressure/io
              ${pkgs.util-linux}/bin/zramctl --bytes --output NAME,DISKSIZE,DATA,COMPR,TOTAL
              # Keep cgroup last and disable width limits so build identities
              # survive ps formatting, including commands containing spaces.
              ${pkgs.procps}/bin/ps -ww -eo pid=,rss=,comm=,cgroup= --sort=-rss \
                | ${pkgs.coreutils}/bin/head -n 11 \
                | ${pkgs.gawk}/bin/awk '{
                  printf "rss_mib=%-8.0f pid=%-8s cgroup=%s comm=", $2/1024, $1, $NF
                  for (i = 3; i < NF; i++) printf "%s%s", (i > 3 ? " " : ""), $i
                  printf "\n"
                }'
            '';
          };
        }
        (lib.genAttrs cfg.modelServices (_: {
          serviceConfig = {
            Slice = "compute.slice";
            OOMPolicy = "kill";
            RestartSec = lib.mkForce "60s";
          };
        }))
      ];

      systemd.timers.rss-watch = {
        description = "Memory-pressure diagnostics every 15 seconds";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "15s";
          OnUnitActiveSec = "15s";
          AccuracySec = "1s";
          Unit = "rss-watch.service";
        };
      };
    };
  };
}
