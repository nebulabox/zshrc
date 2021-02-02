echo "Running my.zshrc"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

setopt EXTENDED_GLOB
autoload -U zmv

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code'
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

complete -cf sudo

platform='unknown'
unamestr=`uname`
if [ -f /proc/version ] && ( grep -q Microsoft /proc/version ) ; then
  platform='wsl'
elif [[ "$unamestr" == 'Linux' ]]; then
  platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
  platform='macos'
elif [[ "$unamestr" == "CYGWIN_NT-10.0" ]]; then
 platform='cygwin'
fi
echo "platform is [$platform]"

function ep {
	if [[ $platform == 'linux' ]]; then
		export http_proxy=http://127.0.0.1:65080;
		export https_proxy=http://127.0.0.1:65080;
	elif [[ $platform == 'macos' ]]; then
		export http_proxy=http://127.0.0.1:1087;
		export https_proxy=http://127.0.0.1:1087;
	fi
	echo "Enable Proxy: $http_proxy"
}
function dp {
	unset http_proxy;
	unset https_proxy;
	echo "Disable Proxy"
}

mask2cdr ()
{
   # mask2cdr 255.255.0.0
   # Assumes there's no "255." after a non-255 byte in the mask
   local x=${1##*255.}
   set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
   x=${1%%$3*}
   echo $(( $2 + (${#x}/4) ))
}
cdr2mask ()
{
   # cdr2mask 16
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

calcimpl() {
	zmodload zsh/mathfunc
	echo $(($1))
}
alias calc="noglob calcimpl"

zshrc_pull() {
	MYRC=$(ls -al ~/my.zshrc)
	AA=(${(s/:/)MYRC})
	BB=$AA[-1]
	CC=(${(s: -> :)BB})
	DD=$CC[-1]
	EE=${DD:h}
	pushd $EE
	git pull origin
	popd
}

zshrc_push() {
	MYRC=$(ls -al ~/my.zshrc)
	AA=(${(s/:/)MYRC})
	BB=$AA[-1]
	CC=(${(s: -> :)BB})
	DD=$CC[-1]
	EE=${DD:h}
	pushd $EE
	git add .
	git commit -m "no msg"
	git pull origin
	git push origin
	popd
}

# usage: tarex <file>
function tarex {
	set -x;
	if [ -f $1 ] ; then
		case $1 in
		*.tar.bz2)   tar xjf $1   ;;
	*.tar.gz)    tar xzf $1   ;;
	*.tar.xz)    tar xvf $1   ;;
	*.bz2)       bunzip2 $1   ;;
	*.rar)       unrar x $1     ;;
	*.gz)        gunzip $1    ;;
	*.tar)       tar xf $1    ;;
	*.tbz2)      tar xjf $1   ;;
	*.tgz)       tar xzf $1   ;;
	*.zip)       unzip $1     ;;
	*.Z)         uncompress $1;;
	*.7z)        7z x $1      ;;
	*)           echo "'$1' cannot be extracted via ex()" ;;
	esac
	else
	echo "'$1' is not a valid file"
	fi
	set +x;
}
# # usage: tarxz <result.file> <input.files>
function tarxz {
  tar pcvfJ $1 --exclude="$1" --exclude=".DS_Store" --exclude="._*" --exclude="thumbs.db" $*
}

build_env_reset() {
	unset CFLAGS
	unset CXXFLAGS
	unset CPPFLAGS
	unset LDFLAGS
	unset CC
	unset CXX
	unset LD
	unset AR
	unset AS
	unset NM
	unset STRIP
	unset RANLIB
	unset OBJDUMP
	unset READELF
	# export PATH="/usr/local/opt/file-formula/bin:/usr/local/opt/unzip/bin:/usr/local/opt/gnu-tar/libexec/gnubin:/usr/local/opt/bzip2/bin:/usr/local/opt/grep/libexec/gnubin:/usr/local/opt/ncurses/bin:/usr/local/opt/gnu-which/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:/usr/local/opt/make/libexec/gnubin:/usr/local/opt/gettext/bin:/usr/local/opt/gnu-getopt/bin:/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/curl/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin" 
}

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ $platform == 'linux' ]]; then
   export YAOURT_COLORS="nb=1:pkg=1:ver=1;32:lver=1;45:installed=1;42:grp=1;34:od=1;41;5:votes=1;44:dsc=0:other=1;35"
elif [[ $platform == 'macos' ]]; then
  export GOROOT_BOOTSTRAP=$HOME/go/bootstrap
  export GOROOT=$HOME/go/go
  export GOPATH=$HOME/go
  export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
  export PATH="/Users/nebulabox/Documents/Scripts:$PATH"
  export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"
  export PATH="/usr/local/opt/openssl/bin:$PATH"
fi

alias sccd='cd /etc/systemd/system && ls'
alias sc='sudo systemctl daemon-reload && sudo systemctl'
alias df='df -h'    # human-readable sizes
alias du='du -h'
alias aria2='aria2c -s16 -k1M -x16 -j16'
alias x='arch -x86_64'
alias qoccg="c++ -std=gnu++17 -fPIC -frtti -fexceptions -g -DDEBUG=1"
alias qocc="c++ -std=gnu++17 -fPIC -frtti -fexceptions -Ofast"
alias brewx="arch -x86_64 /usr/local/bin/brew"
alias pl="print -l"

export HOMEBREW_GITHUB_API_TOKEN='4ebf9c5d07652a66f9da59597bf1fb7396af8dfc'

export GOROOT_BOOTSTRAP="${HOME}/go/go-bootstrap"
export GOROOT="${HOME}/go/gosrc"
export GOPATH="${HOME}/go"
export PATH=${GOPATH}/bin:${GOROOT}/bin:$PATH

export PATH=/Users/nebulabox/sync/bin:/Users/kliu/sync/bin:$PATH:/sbin


