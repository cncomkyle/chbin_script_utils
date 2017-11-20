


function getJarContent()
{
    local jar_name="$1"
    
    unzip -l "${jar_name}" | \
    awk '{printf"%s:%s\n",jar_name,$0;}' jar_name="${jar_name}"
}

function findJarClass()
{
    local find_dir="./"

    if [ $# -gt 1 ] 
    then
        local find_dir="$1"
        local classNmPattern="$2"
    else
        local classNmPattern="$1"        
    fi

    local jar_file_list=$(find "${find_dir}" -type f -name '*.jar')

    while read -r tmp_jar_path
    do
        getJarContent "${tmp_jar_path}"| \
        sed -n -e '/'${classNmPattern}'/p'
    done <<< "${jar_file_list}"
}

function findJPSJar_old()
{
    local classNmPattern="$1"
    
    if [ -z "${classNmPattern}" ]
    then
        printf "Please input the search class name pattern value!\n"
        return 1
    fi
    
    ps -ef 2>&1 | \
    grep java | \
    sed -n -e '/grep/!p' | \
    awk '{print $2}' | \
    awk '{cmd="lsof -p "$0;system(cmd);close(cmd);}' | \
    sed -n -e '/\.jar$/p' | \
    awk '{print $NF}' | \
    sort | \
    uniq | \
    awk '{cmd="dirname "$0;system(cmd);close(cmd);}' | \
    sort | \
    uniq | \
    xargs -n1 -I{} bash -c "findJarClass {} ${classNmPattern}"
}

function findJPSJar()
{
    local classNmPattern="$1"
    
    if [ -z "${classNmPattern}" ]
    then
        printf "Please input the search class name pattern value!\n"
        return 1
    fi
    
    local pid_info_list=$(
        ps -ef 2>&1 | \
        grep java | \
        sed -n -e '/grep/!p' 
    )

    if [ -z "${pid_info_list}" ]  
    then
        printf "%s\n" "Empty Java PID List!\n"
        return 0
    fi

    while read -r tmp_pid_info
    do
        local tmp_pid=$(printf "%s\n" "${tmp_pid_info}" | awk '{print $2}')

        local tmp_rlt=$(
            printf "%s\n" "${tmp_pid}" | \
            awk '{cmd="lsof -p "$0;system(cmd);close(cmd);}' | \
            sed -n -e '/\.jar$/p' | \
            awk '{print $NF}' | \
            sort | \
            uniq | \
            xargs -n1 -I{} bash -c "getJarContent {}" | \
            sed -n -e '/'${classNmPattern}'/p' | \
            color_sed ${classNmPattern} | \
            color_file_path | \
            awk '{printf"#%d. %s\n",FNR,$0;}'
        )
        
        if [ -z "${tmp_rlt}" ]  
        then
            continue
        fi
        
        local tmp_pid_cwd=$(lsof -p "${tmp_pid}" | awk '{if($4~/cwd/)print $NF}')
        local tmp_pid_exe=$(printf "%s\n" "${tmp_pid_info}" | awk '{print $8}')

        printf "%b %b %b\n%b\n" "$(getColorStr ${bold_yellow_color} ${tmp_pid})" "$(getColorStr ${bold_magenta_color} ${tmp_pid_cwd})" "$(getColorStr ${bold_cyan_color} ${tmp_pid_exe})" "${tmp_rlt}"
    done <<< "${pid_info_list}"

}

function getJPIDJars()
{
    local tmp_jpid="$1"
    if [ -z "${tmp_jpid}" ]  
    then
        printf "Please input the check java pid\n"
        return 1
    fi

    local tmp_rlt=$(
        lsof -p "${tmp_jpid}" | \
        sed -n -e '/\.jar$/p' | \
        awk '{print $NF}' | \
        sort | \
        uniq | \
        color_file_path
    )
    
    printf "%b\n" "${tmp_rlt}"
}

function jarDiff()
{
    local tmp_src_jar_list_path="$1"
    local tmp_dst_jar_list_path="$2"

    if [ "$#" -ne 2 ]
    then
        printf "Please input {src jar list path} and {dst jar list path}\n"
        return 1
    fi

    if [ ! -e "${tmp_src_jar_list_path}" ]
    then
        printf "The %s does't exist!\n" "${tmp_src_jar_list_path}"
        return 1
    fi

    if [ ! -e "${tmp_dst_jar_list_path}" ]
    then
        printf "The %s does't exist!\n" "${tmp_dst_jar_list_path}"
        return 1
    fi

    local tmp_jar_path=""
    local tmp_check_cnt=0
    while read -r tmp_jar_path
    do
        tmp_check_cnt=0
        tmp_check_cnt=$(
            cat "${tmp_dst_jar_list_path}" | \
            awk '{if($0 ~ tmpPath){print $0}}' tmpPath="${tmp_jar_path}" | \
            wc -l
        )
        if [ "${tmp_check_cnt}" -eq 0 ]
        then
            printf "%s\n" "${tmp_jar_path}"
        fi
    done < "${tmp_src_jar_list_path}"
}

function getAllJarClass()
{
    local tmp_jar_list_file_path="$1"

    while read -r tmp_jar_path
    do
        if [ ! -e "${tmp_jar_path}" ]
        then
            continue
        fi
        getJarContent "${tmp_jar_path}"
    done < "${tmp_jar_list_file_path}"
}

function importClassJarMatch()
{
    local tmp_check_class_list_file_path="$1"
    local tmp_all_jar_class_list_file_path="$2"

    while read -r tmp_check_class
    do
        cat "${tmp_all_jar_class_list_file_path}" | \
        awk '{if($0 ~ check_class_name){printf"%s#%s\n",$0, check_class_name}}' check_class_name="${tmp_check_class}.class"
    done < "${tmp_check_class_list_file_path}"
}

function fullClassNameJarMatch()
{
    local tmp_classNm_list_file_path="$1"
    local tmp_all_jar_class_list_file_path="$2"

    local tmp_check_classNm=""
    while read -r tmp_check_classNm
    do
        tmp_check_classNm=$(
            printf "%s\n" "${tmp_check_classNm}" | \
            sed -n -e 's/\//\\\//g;p;'
        )
        cat "${tmp_all_jar_class_list_file_path}" | \
        sed -n -e '/'"${tmp_check_classNm}"'/p'
    done < "${tmp_classNm_list_file_path}"
}

function sameClassJarList()
{
    local tmp_classNm_list_file_path="$1"
    local tmp_all_jar_class_list_file_path="$2"

    local tmp_check_classNm=""
    local tmp_jar_list=""
    while read -r tmp_check_classNm
    do
        tmp_check_classNm=$(
            printf "%s\n" "${tmp_check_classNm}" | \
            sed -n -e 's/\//\\\//g;p;'
        )
        tmp_same_jar_list=$(
            cat "${tmp_all_jar_class_list_file_path}" | \
            sed -n -e '/'"${tmp_check_classNm}"'/p' | \
            awk -F ':' '{print $1}' | \
            awk -F '/' '{print $NF}'
        )

        printf "%s\n" "${tmp_same_jar_list}" | \
        awk 'BEGIN{printf"%s::",classNm}{printf"#%s",$0}END{printf"\n"}' classNm="${tmp_check_classNm}"
    done < "${tmp_classNm_list_file_path}"
}


function jarExistCheck()
{
    local tmp_origin_jar_list_file_path="$1"
    local tmp_dst_jar_list_file_path="$2"

    local tmp_check_jar_name=""

    while read -r tmp_check_jar_name
    do
        cat "${tmp_dst_jar_list_file_path}" | \
        sed -n -e 's/\('"${tmp_check_jar_name}"'\)/>**\1**</gp;'
    done < "${tmp_origin_jar_list_file_path}"
}


function pidJarExistCheck()
{
    local tmp_origin_jar_list_file_path="$1"
    local tmp_dst_jar_list_file_path="$2"

    local tmp_check_jar_name=""

    while read -r tmp_check_jar_name
    do
        cat "${tmp_dst_jar_list_file_path}" | \
        sed -n -e 's/#\('"${tmp_check_jar_name}"'\)/#>**\1**</gp;'
    done < "${tmp_origin_jar_list_file_path}"
}

export -f getJarContent
export -f findJarClass
export -f findJPSJar
export -f getJPIDJars

# function main()
# {
#     findJarClass "${class_nm_str}"
# }

# main
