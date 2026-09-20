# bees — btrfs offline dedup daemon (https://github.com/zygo/bees).
# Merges duplicate extents filesystem-wide; combines with zstd compression
# (dedup preserves per-extent compression — no need to disable it).
# One entry per *filesystem*: @/@home/@nix/@log share one pool → spec "/".
{
  config,
  lib,
  ...
}: let
  cfg = config.myconf.nixos.bees;
in {
  options.myconf.nixos.bees = {
    enable = lib.mkEnableOption "bees btrfs dedup daemon";

    hashTableSizeMB = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "bees hash-table size in MB (mlocked RAM, must be a multiple of 16). 2048 desktop / 1024 laptop.";
    };

    loadavgTarget = lib.mkOption {
      type = lib.types.either lib.types.int lib.types.float;
      default = 4;
      description = "bees throttles its workers to stay under this load average.";
    };

    threadCount = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "bees worker thread count.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.beesd.filesystems.root = {
      spec = "/";
      hashTableSizeMB = cfg.hashTableSizeMB;
      verbosity = "crit";
      extraOptions = [
        "--loadavg-target"
        (toString cfg.loadavgTarget)
        "--thread-count"
        (toString cfg.threadCount)
      ];
    };
  };
}
