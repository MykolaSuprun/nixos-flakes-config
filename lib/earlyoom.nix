{pkgs}: let
  # Match /proc/PID/comm, including versioned interpreters and wrapped names.
  prefer = "^(strata|strata-vision-h|comfyui|llama-server|ollama|python([0-9]+([.][0-9]+)*)?|rustc|cc1|cc1plus|lto1)$";
  avoid = "^([.]Hyprland-wrapp|Hyprland|Xwayland|[.]quickshell-wra|quickshell|hypridle|hyprpolkitagent|start-hyprland|systemd.*|sshd|greetd|uwsm|[.]lianli-daemon-|lianli-daemon|pipewire.*|wireplumber|ChatGPT.*)$";
in {
  inherit prefer avoid;

  package = pkgs.earlyoom.overrideAttrs (old: {
    pname = "earlyoom-rss-fixed";
    patches = (old.patches or []) ++ [../patches/earlyoom-rss-avoid.patch];

    # Exercise upstream's real selector against synthetic /proc entries. No
    # memory exhaustion or signals are needed to reproduce the avoidance bug.
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      $CC -std=gnu99 -Wall -Wextra -I. \
        ${../scripts/test-earlyoom.c} \
        globals.c kill.c meminfo.c msg.c proc_pid.c -o earlyoom-regression
      mkdir mock-proc
      ./earlyoom-regression "$PWD/mock-proc" \
        ${pkgs.lib.escapeShellArg prefer} ${pkgs.lib.escapeShellArg avoid}
      runHook postCheck
    '';
  });
}
