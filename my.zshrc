# If not running interactively, don't do anything
# [[ $- != *i* ]] && return

####################################  Common ENV ####################################
script_file=${0:A}
script_folder=${0:A:h}
echo "Running ${script_file}"

# prompt, use prompt -l for more themes
autoload -Uz promptinit
promptinit
prompt adam1

# bind key to vi mode
# bindkey -v

setopt extendedglob         # Extended globbing. Allows using regular expressions with *
setopt nocaseglob           # Case insensitive globbing
setopt rcexpandparam        # Array expansion with parameters
setopt numericglobsort      # Sort filenames numerically when it makes sense
setopt nobeep               # No beep
setopt appendhistory        # Immediately append history instead of overwriting
setopt histignorealldups    # If a new command is a duplicate, remove the older one
setopt sharehistory         # Import new comands and appends typed commands to history
setopt interactivecomments  #  allow comment on interactive command line

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Theming section
autoload -U compinit colors zcalc
compinit -d
colors

# Figure out the SHORT hostname
if [[ "$OSTYPE" = darwin* ]]; then
  # macOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
  SHORT_HOST=$(scutil --get ComputerName 2>/dev/null) || SHORT_HOST=${HOST/.*/}
else
  SHORT_HOST=${HOST/.*/}
fi

zstyle ':completion:*' rehash true                              # automatically find new executables in path 

# 修改名字 zmv '(*).pdf' '$1.txt'
autoload -U zmv

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code'
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

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
elif [[ "$unamestr" =~ "MSYS_NT" ]]; then
 platform='msys'
fi
echo "platform is [$platform]"

####################################  Plugins ####################################
run_plugin() {
	if [[ -f ${1} ]]; then
		source ${1}
		echo "${1:t} enabled"
	else
		echo "[Warning]NOT Found: ${1}"
	fi
}
# https://github.com/zsh-users/zsh-autosuggestions
run_plugin "${script_folder}/zsh-autosuggestions/zsh-autosuggestions.zsh"
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50

# https://github.com/zsh-users/zsh-syntax-highlighting
run_plugin "${script_folder}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# https://github.com/zsh-users/zsh-history-substring-search
run_plugin "${script_folder}/zsh-history-substring-search/zsh-history-substring-search.zsh"
#bindkey '^[[A' history-substring-search-up
#bindkey '^[[B' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

####################################  My Functions ####################################
function ep {
	export http_proxy=http://127.0.0.1:51088;
	export https_proxy=http://127.0.0.1:51088;
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
alias c="noglob calcimpl"

zshrc_pull() {
	pushd ~/zshrc
	git pull origin
	popd
}

zshrc_push() {
	ep
	pushd ~/zshrc 
	git add .
	git commit -m "no msg"
	git pull origin
	git push origin
	popd
	dp
}

# usage: tarex <file>
tarex() {
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
tarxz() {
  tar pcvfJ $1 --exclude="$1" --exclude=".DS_Store" --exclude="._*" --exclude="thumbs.db" $*
}

tarit() {
  tar pcvf $1 --exclude="$1" --exclude=".DS_Store" --exclude="._*" --exclude="thumbs.db" $*
}

build_env_reset() {
    unset CFLAGS; unset CXXFLAGS; unset CPPFLAGS; unset LDFLAGS; unset CC; unset CXX; unset LD; unset AR; unset AS; unset NM; unset STRIP; unset RANLIB; unset OBJDUMP; unset READELF
	export PATH="/usr/local/opt/file-formula/bin:/usr/local/opt/unzip/bin:/usr/local/opt/gnu-tar/libexec/gnubin:/usr/local/opt/bzip2/bin:/usr/local/opt/grep/libexec/gnubin:/usr/local/opt/ncurses/bin:/usr/local/opt/gnu-which/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:/usr/local/opt/make/libexec/gnubin:/usr/local/opt/gettext/bin:/usr/local/opt/gnu-getopt/bin:/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/curl/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin" 
}

ff_cvt_smallest() {
	ffmpeg -y -hide_banner -i $1 -profile:v main -sn -vcodec libx265 -crf 33 -acodec aac -b:a 64k -tag:v hvc1 -movflags +faststart ${1:r}.smallest.mp4
}

ff_cvt_small() {
	ffmpeg -y -hide_banner -i $1 -profile:v main -sn -vcodec libx265 -crf 28 -acodec aac -b:a 96k -tag:v hvc1 -movflags +faststart ${1:r}.small.mp4
}

ff_cvt_middle() {
	ffmpeg -y -hide_banner -i $1 -profile:v main -sn -vcodec libx265 -crf 25 -acodec aac -b:a 128k -tag:v hvc1 -movflags +faststart ${1:r}.middle.mp4
}

ff_cvt_best() {
	ffmpeg -y -hide_banner -i $1 -profile:v main -sn -vcodec libx265 -crf 22 -acodec aac -b:a 192k -tag:v hvc1 -movflags +faststart ${1:r}.best.mp4
}

ff_extract_audio_to_m4a() {
	ffmpeg -i $1 -dn -vn -sn -acodec 'aac' ${1%.*}.m4a
}

pdf_compress ()
{
	if {which pdfsizeopt} {
		pdfsizeopt $1 ${1%.*}.compressed.pdf
	} elif {which gs} {
		gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dEmbedAllFonts=true -dSubsetFonts=true -sOutputFile=${1%.*}.compressed.pdf $1
	} else {
		echo "Need 'pdfsizeopt' or 'ghostscript' "
	}
}

dec2bin() {
	local -i 2 i=$1
	echo $i
}
dec2hex() {
	local -i 16 i=$1
	echo $i
}
hex2dec() {
	echo $((16#$1))
}
bin2dec() {
	echo $((2#$1))
}
hex2bin() {
	local -i 2 i=$(( $((16#$1)) ))
	echo $i
}
bin2hex() {
	local -i 16 i=$(( $((2#$1)) ))
	echo $i
}

env_ac86u() {
	. $HOME/kall/cross_libs/env_ac86u.zsh
}

kcc() {
	# alias k_debug="c++ -std=gnu++2a -fPIC -frtti -fexceptions -fmodules -g -DDEBUG=1"
    # alias k_release="c++ -std=gnu++2a -fPIC -frtti -fexceptions -fmodules -Ofast"
	export LDFLAGS="-L/usr/local/opt/llvm/lib -Wl,-rpath,/usr/local/opt/llvm/lib"
    export CPPFLAGS="-I/usr/local/opt/llvm/include"
	/usr/local/opt/llvm/bin/clang++ -std=gnu++20 -fPIC -frtti -fexceptions -fmodules -g -DDEBUG=1 $*
	unset LDFLAGS
	unset CPPFLAGS
}

##### ssh-agent ######
mkdir -p ~/.ssh
env=~/.ssh/agent.env
agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }
agent_start () {
    (umask 077; ssh-agent >| "$env")
    . "$env" >| /dev/null ; }
ssh_add_pk () {
	passwd=$(<~/.keypasswd)
	if [ ! $? -eq 0 ]; then
		echo "=====>>>>> Need ~/.keypasswd for auto ssh_add"
		return
	fi
	/usr/bin/expect <<-EOF
	set time 30
	spawn ssh-add
	expect {
	"*passphrase for*" { send "$passwd\r"; }
	}
	expect eof
	EOF
	ssh-add -l
}
agent_load_env
# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)
if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh_add_pk
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh_add_pk
fi
unset env


find_port() {
	echo "sudo lsof -nP -iTCP:$1 | grep LISTEN"
	sudo lsof -nP -iTCP:$1 | grep LISTEN
}

find_ports() {
	echo "sudo lsof -i -P | grep LISTEN"
	sudo lsof -i -P | grep LISTEN
}

####################################  Alias ####################################
if [[ $platform == 'linux' ]]; then
   alias sccd='cd /etc/systemd/system && ls'
   alias sc='sudo systemctl daemon-reload && sudo systemctl'
   alias ls='ls --color'
   alias ll='ls --color -al'
elif [[ $platform == 'macos' ]]; then
  export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
  alias ls='/bin/ls -G'
  alias ll='/bin/ls -al -G'

  export GOROOT_BOOTSTRAP=$HOME/go/go1.4
  #export GOROOT=$HOME/go/gosrc
  #export GOPATH=$HOME/go
  export PATH="$HOME/go/bin:$HOME/go/gosrc/bin:$PATH"
elif [[ $platform == 'msys' ]]; then
  export PATH="/c/Program Files/Microsoft VS Code/bin:$PATH"
fi

if { which vim > /dev/null } {
	alias vi='vim'
}

alias df='df -h'    # human-readable sizes
alias du='du -h'
alias x86='arch -x86_64'
alias pl="print -l"
alias apt-update-all="sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y"

alias wine="LC_ALL=zh_CN.GBK /usr/local/bin/wine"
alias xiadan="LC_ALL=zh_CN.GBK /usr/bin/nohup /usr/local/bin/wine /Users/nebulabox/.wine/drive_c/htwt/xiadan.exe > /dev/null 2&>/dev/null &"
alias tdx="LC_ALL=zh_CN.GBK /usr/bin/nohup /usr/local/bin/wine /Users/nebulabox/.wine/drive_c/tdx/TdxW.exe > /dev/null 2&>/dev/null &"
alias killwine="/usr/bin/killall wine32on64-preloader"


alias aria2='aria2c -s16 -k1M -x16 -j16'
alias youtube-dl-audio="youtube-dl -f 'bestaudio[ext=m4a]' "
alias youtube-dl-video="youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]' "
alias youtube-dl-listformats="youtube-dl -F "


echo "run zshrc_pull on sub shell"
(zshrc_pull >/dev/null 2>/dev/null &)

####################################  Others ####################################
export PATH=/Users/nebulabox/sync/bin:/Users/kliu/sync/bin:$PATH:/sbin
# more system environment vars set in ~/Library/LaunchAgents/environment.plist


