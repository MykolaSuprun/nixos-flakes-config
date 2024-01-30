#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
nxcnf_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

if [ -n "$1" ] && [ -n "$2" ]; then
  if [ "$1" = "build" ]; then
    if [ "$2" = "os" ]; then
      echo "building nixos ..."
      if [ -z "$3" ]; then
        if [ -z "$nixos_target" ]; then
          echo "No nixos target. Either set a nixos_target variable or pass it as 2nd parameter"
        else
          rm ~/.gtkrc-2.0
          pushd "$nxcnf_dir" || exit
          sudo nixos-rebuild switch --flake .#"$nixos_target"
          popd || exit
        fi
      else
        rm ~/.gtkrc-2.0
        pushd "$nxcnf_dir" || exit
        sudo nixos-rebuild switch --flake .#"$3"
        popd || exit
      fi
    elif [ "$2" = "home" ]; then
      echo "building home ..."
      if [ -z "$3" ]; then
        if [ -z "$home_manager_target" ]; then
          echo "No home manager target. Either set a home_manager_target variable or pass it as 2nd parameter"
        else
          pushd "$nxcnf_dir" || exit
          home-manager switch --flake .#"$home_manager_target"
          # nix build .#homeConfigurations."$home_manager_target".activationPackage
          # ./result/activate
          popd || exit
        fi
      else
        pushd "$nxcnf_dir" || exit
        nix build .#homeConfigurations."$3".activationPackage
        ./result/activate
        popd || exit
      fi
    else
      echo "build either "os" or "home""
    fi
  fi
elif [ -n "$1" ]; then
  if [ "$1" = "update" ]; then
    echo "updating nxconf..."
    pushd "$nxcnf_dir" || exit
    nix flake update
    popd || exit
  elif [ "$1" = "build" ]; then
    echo "build either "os" or "home""
  fi
else
  echo "either "update" or "build" nxcnf"
fi

