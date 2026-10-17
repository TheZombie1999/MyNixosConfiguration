{
  disko.devices = {
    disk = {
      # Dedicated boot/root disk, matching the original Proxmox layout where
      # this disk carried pve-root/pve-swap and the two EDILOCA disks were a
      # separate ZFS mirror used only for VM/container storage.
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Netac_SSD_120GB_YS202010004535790885";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      mirror1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-EDILOCA_EN206_512GB_MX_00000000000011225";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
      mirror2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-EDILOCA_EN206_512GB_MX_00000000000021173";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      # Storage-only mirror (Incus), not the OS root -- root lives on `boot`.
      rpool = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          incus = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
