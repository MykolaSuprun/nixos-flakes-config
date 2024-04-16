  #!/usr/bin/env bash
  FILE=/home/mykolas/.config/ext-ssd/keyfile
  if test -f "$FILE"; then
    # if ! grep '/dev/mapper/external-ssd' /etc/mtab > /dev/null 2>&1; then
    lsof | grep "/mnt/external" | gawk '{print $2}' | sudo xargs -I -r kill
    if sudo mountpoint -q /mnt/external/ ; then
      sudo umount /mnt/external
    fi
    if [ $(lsblk -l -n /dev/disk/by-uuid/2826d16b-a4d0-408d-9c36-b45d476fbe14 | wc -l) -gt 1 ]; then
      sudo cryptsetup luksClose external-ssd
    fi
    if [ $(lsblk -l -n /dev/mapper/external-ssd | wc -l) -gt 0 ]; then
      sudo cryptsetup luksClose external-ssd
    fi
    if lsblk -f | grep -wq 2826d16b-a4d0-408d-9c36-b45d476fbe14; then
      sudo cryptsetup luksOpen /dev/disk/by-uuid/2826d16b-a4d0-408d-9c36-b45d476fbe14 external-ssd --key-file /home/mykolas/.config/ext-ssd/keyfile
      sudo mount /dev/mapper/external-ssd /mnt/external
      if [ $(ps aux | grep megasync | wc -l) -gt 1 ]; then
      megasync
      fi
    fi
  fi
