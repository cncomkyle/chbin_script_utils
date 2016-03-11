## set the name of each tab for terminal window
function tabName()
{
    echo -n -e "\033]0;$1\007"
}

# go up parent folder with n levets
function ucd()
{
    
    local dest_path="$(pwd)"
    local newcd_cnt=1
    local newcd_num=$@
    while [ "${newcd_cnt}" -le "${newcd_num}" ]
    do
        dest_path=$(dirname "${dest_path}")
        newcd_cnt=$((newcd_cnt+1))
    done
    cd "${dest_path}"
}

# get the maven dependency build-classpath exact file path list
# function getMvnDep()
# {
#     mvn dependency:build-classpath 2>&1 | sed -n -e '/\.jar/p' | sed -n -e '/http:/!p' |  awk -F ':' '{for(i=1;i<=NF;i++)print$i}'
# }

function getExportFuncList()
{
    local shell_file_path="$1"

    if [ -z "${shell_file_path}" ]
    then
        printf "Please input the shell file path!\n"
        return 1
    fi

    if [ ! -e "${shell_file_path}" ]
    then
        printf "The shell file path doesnot exist!\n"
        return 1
    fi

    cat "${shell_file_path}" | \
    sed -n -e '/^function/p'  | \
    awk '{print $NF}' | \
    sed -n -e 's/()//g;p;' | \
    awk '{printf"export -f %s\n",$0}'
}


function getPIDInfo()
{
    local tmp_pid="$1"

    if [ -z "${tmp_pid}" ]  
    then
        printf "Please input the search pid value!\n"
        return 0
    fi
    
    local tmp_rlt=$(
        ps -ef 2>&1 | \
        awk '{if($2~chk_pid)print $0}' chk_pid="${tmp_pid}" | \
        awk '{for(i=1;i<=NF;i++){if(i>=8)print $i}}' | \
        awk -F ':' '{for(i=1;i<=NF;i++)print $i}' | \
        color_file_path
    )

    printf "%b\n" "${tmp_rlt}"

}

function checkCmdExist()
{
    local cmd_name="$1"

    if [ -z "${cmd_name}" ]
    then
        return 0
    fi

    if ! which "${cmd_name}" > /dev/null 2>&1 
    then
        printf "Cannot find %s !\n" "${cmd_name}"
        return "${LINENO}"
    fi
}

function sendMacOSNotification()
{
    if ! checkCmdExist "terminal-notifier" 
    then
        return 1
    fi

    local tmp_title="$1"
    local tmp_rlt_status="$2"
    local tmp_msg="${tmp_title} Successfully!"

    if [  "${tmp_rlt_status}" != "0" ]
    then
        tmp_msg="${tmp_title} Failed!"
    fi

    local tmp_date_time="$(date +%Y_%m_%d:%H_%M_%S)"

    terminal-notifier -title "${tmp_date_time}#${tmp_msg}#" -message "${tmp_msg}"
}

function executeShellCmd()
{
    local tmp_shell_cmd="$1"
    local tmp_title="$2"

    # if [ ! -e "${tmp_shell_cmd}" ]
    # then
    #     printf "Invalid shell Path:%s\n" "${tmp_shell_cmd}"
    #     return 1
    # fi
    
    local tmp_date_time="$(date +%Y_%m_%d:%H_%M_%S)"
    
    tabName "${tmp_date_time}#${tmp_title}"

    eval "sh ${tmp_shell_cmd}"
    
    sendMacOSNotification "${tmp_title}" "$?"
}

#=== export function area ==========
export -f tabName
export -f ucd
export -f getExportFuncList
export -f getPIDInfo
export -f checkCmdExist
export -f sendMacOSNotification
export -f executeShellCmd
