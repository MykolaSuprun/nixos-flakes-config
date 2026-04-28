alias ls='ls --color=auto'
# `PS1='[\u@\h \W]\$ '

if [[ $(uname -a | grep arch) ]]
then 
	distrobox-host-exec xhost +local:
	xhost +SI:localuser:$USER
	alias vi='nvim'
	alias vim='nvim'
	alias nano='nvim'
	# echo "in Arch" 
	# zsh
	clear
else 
	alias vi='nvim'
	alias vim='nvim'
	alias nano='nvim'
	alias editconf='code ~/.dotfiles'
	alias sysbuild='~/.dotfiles/apply-system.sh'
	alias hmbuild='"~/.dotfiles/update.sh"'
	alias sysupdate='~/.dotfiles/update.sh'
	alias confdir='~/.dotfiles'
	alias nsgc='nix-collect-garbage'
	alias arch='distrobox-enter arch'
	# echo "in NixOS"
	clear
fi
