# export PS1="[\$(date +%Y_%m_%d#%H:%M:%S)]\[\e[31;1m\h@\033[0m[\w]\n$> "
function getFormatPWD()
{
    local current_dir_path=$(pwd)

    local rlt=$(printf "%s\n" "${current_dir_path}" | \
    awk -F '/' '{for(i=2;i<=NF;i++)printf"\\e[1m/%s\\e[0m\\e[2;33m/%d/\\e[0m",$i,(NF-i);printf"\n"}')

    printf "%b\n" "${rlt}"
    

}

export PS1="[\033[4;97m\$(date +%Y_%m_%d#%H:%M:%S)\e[0m]\[\e[31;1m\h@\033[0m[\$(getFormatPWD)]\n$> "

export CLICOLOR=1
export LSCOLORS=edfccbdxbeegedabagacad
export LSCOLORS=ExFxBxDxCxegedabagacad
