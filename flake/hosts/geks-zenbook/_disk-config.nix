{
  lib,
  ...
}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/null";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          cryptroot = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
                  };
                  "@swap" = {
                    mountpoint = "/.swapvol";
                    mountOptions = [ "noatime" "discard=async" ];
                    swap.swapfile.size = "32G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}