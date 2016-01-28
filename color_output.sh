#!/bin/bash

bold_red_color="\033[1;31m"
bold_white_color="\033[1;97m"
bold_yellow_color="\033[1;33m"
bold_blue_color="\033[1;4;34m"
bold_magenta_color="\033[1;35m"
bold_cyan_color="\033[1;36m"
bold_gray_color="\033[1;90m"

bold_white_red_color="\033[1;97;41m"
bold_yellow_blue_color="\033[1;33;104m"
color_end_str="\033[0m"

sed_bold_white_red_color="\\\033[1;97;41m"
sed_color_end_str="\\\033[0m"


function getColorStr()
{
    local color_value="$1"
    local origin_str="$2"

    local end_str="$3"

    if [ -z "${end_str}" ]
    then
        end_str="${color_end_str}"
    fi

    printf "%s%s%s\n" "${color_value}" "${origin_str}" "${end_str}"
}

function regMatchCheck()
{
    local checkStr="$1"
    local matchStr="$2"

    checkStr=$(printf "%s\n" "${checkStr}" | awk '{print tolower($0)}')
    matchStr=$(printf "%s\n" "${matchStr}" | awk '{print tolower($0)}')

    local checkRlt=$(printf "%s\n" "${checkStr}" | sed -n -e '/'"${matchStr}"'/p')

    if [ -n "${checkRlt}" ]
    then
        return 0
    else
        return 1
    fi
}

function color_log_level()
{
    local log_level_str="$1"
    # replate blank char
    # log_level_str=$(printf "%s\n" "${log_level_str}" | sed -n -e 's/[[:blank:]][[:blank:]]*//g;p;')

    # if $(regMatchCheck "${log_level_str}" "error")
    if [ "${log_level_str}" == "ERROR" ]
    then
        #match
        printf "%s\n" $(getColorStr "${bold_white_red_color}" "${log_level_str}")
        return 0

    elif [ "${log_level_str}" == "DEBUG" ] ||  [ "${log_level_str}" == "TRACE" ] || [ "${log_level_str}" == "INFO" ]
    then
        # unmatch
        printf "%s\n" $(getColorStr "${bold_red_color}" "${log_level_str}")
        return 0
    fi
}

function color_class_method()
{
    local class_method_str="$1"

    while IFS="#" read -r tmp_class_name tmp_method_name
    do
        printf "%s#%s" $(getColorStr "${bold_yellow_blue_color}" "${tmp_class_name}") $(getColorStr "${bold_yellow_color}" "${tmp_method_name}")
    done <<< "${class_method_str}"
}

function color_log_line()
{

    while read -r log_level log_thread log_date log_time log_class_method log_line_start log_line_end log_string
    do
        new_log_level=$(color_log_level "${log_level}")

       
        if [ -n "${new_log_level}" ]
        then
            log_thread=$(getColorStr "${bold_gray_color}" "${log_thread}")
            log_date_time=$(getColorStr "${bold_blue_color}" "${log_date} ${log_time}")
            log_class_method="$(color_class_method "${log_class_method}")"
            log_line=$(getColorStr "${bold_magenta_color}" "${log_line_start} ${log_line_end}")
            log_string=$(getColorStr "${bold_cyan_color}" "${log_string}")

            printf "%b %b %b %b %b %b\n" "${new_log_level}" "${log_thread}" "${log_date_time}"  "${log_class_method}" "${log_line}" "${log_string}"            
        else
            log_string=$(getColorStr "${bold_cyan_color}" "${log_level} ${log_thread} ${log_date} ${log_time} ${log_class_method} ${log_line_start} ${log_line_end} ${log_string}")
            printf "%b\n" "${log_string}"
        fi
    done
}



function color_log()
{
    local log_file_path="$1"
    # tail -fn 100 "${log_file_path}" | \
    # awk '{printf"%s%s%s",begin_str,$1,end_str;for(i=2;i<=NF;i++)printf" %s",$i;printf"\n"}' begin_str="\033[1;31m" end_str="\033[0m"

    if [ -n "${log_file_path}" ]
    then
        tail -fn 500 "${log_file_path}" | \
        color_log_line
    else
        color_log_line
    fi
}

function color_sed()
{
    local reg_pattern_str="$1"
    if [ -z "${reg_pattern_str}"  ]
    then
        return 0
    fi
    
    while read -r tmp_line
    do
        printf "%s\n" "${tmp_line}" | \
        sed -n -e '/'"${reg_pattern_str}"'/{
            s/'"${reg_pattern_str}"'/'$(getColorStr "${sed_bold_white_red_color}" "${reg_pattern_str}" "${sed_color_end_str}")'/g;
            p;
        }' | \
        awk '{cmd="echo  \""$0"\"";system(cmd);close(cmd)}'
    done
}
