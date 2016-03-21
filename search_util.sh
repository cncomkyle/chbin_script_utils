#!/bin/bash

function printSearchFileStrUsage()
{
    printf "searchFileStr [ -t file type]+ [ -p search string pattern ]+ [ -x exclude path name]*\n"
    return 0
}

function searchSingleFile()
{
    local l_file_path="$1"
    local l_match_str="$2"

    local l_rlt=""

    local l_line_num=1
    local l_line_rlt=""

    l_rlt=$(
        cat -n "${l_file_path}" | \
        sed -n -e 's/^\([[:blank:]]*\)\([1-9][0-9]*\)\([[:blank:]][[:blank:]]*\)\(.*\)/\4##Line[\2]:/g;;p;' | \
        sed -n -e '/'"${l_match_str}"'/p' | \
        color_sed "${l_match_str}" | \
        awk -F '##' '{printf"%s %s\n",$2,$1}'
    )


    l_rlt=$(
        cat -n "${l_file_path}" | \
        sed -n -e 's/^\([[:blank:]]*\)\([1-9][0-9]*\)\([[:blank:]][[:blank:]]*\)\(.*\)/\4##Line[\2]:/g;;p;' | \
        sed -n -e '/'"${l_match_str}"'/p' | \
        color_sed "${l_match_str}" | \
        awk -F '##' '{printf"%s %s\n",$2,$1}'
    )

    if [ -z "${l_rlt}" ]  
    then
        return 0
    fi

    local l_print_file_path=$(
        printf ">>> File %s Total:%d <<<\n" ${l_file_path} $(printf "%s\n" "${l_rlt}" | wc -l)| \
        sed -n -e 's/\([^\/][^\/]*\)/'$(getSedColorStr  "${bold_yellow_color}" "\1")'/g;p;' | \
        color_file_path
    )

    printf "%b\n%s\n" "${l_print_file_path}"  "${l_rlt}"

}

function searchFileStr()
{
    if [ "$#" -le 0 ]
    then
        printSearchFileStrUsage
        return 0
    fi

    local l_opts="t:p:x:"
    local l_opt=""
    local OPTIND

    local l_file_names[0]=""
    local l_file_name_idx=0
    local l_pattern_strs[0]=""
    local l_pattern_str_idx=0
    local l_exclude_paths[0]=""
    local l_exclude_path_idx=0
    
    while getopts "${l_opts}" l_opt
    do
        case "${l_opt}" in
            t) l_file_names["${l_file_name_idx}"]=$OPTARG
                let l_file_name_idx=$l_file_name_idx+1
                ;;
            p) l_pattern_strs["${l_pattern_str_idx}"]=$OPTARG
                let l_pattern_str_idx=$l_pattern_str_idx+1
                ;;
            x) l_exclude_paths["${l_exclude_path_idx}"]=$OPTARG
                let l_exclude_path_idx=$l_exclude_path_idx+1
                ;;
            *) printSearchFileStrUsage
               return 1
               ;;
        esac
    done

    shift "$(( $OPTIND - 1 ))"

    if [ -z "${l_file_names[0]}" ]
    then
        printSearchFileStrUsage
        return 1
    fi

    if [ -z "${l_pattern_strs[0]}"  ]
    then
        printSearchFileStrUsage
        return 1
    fi

    l_file_name_idx=0

    local l_file_names_str=""
    while [ "${l_file_name_idx}" -lt "${#l_file_names[@]}" ]
    do
        if [ -z "${l_file_names_str}" ]  
        then
            l_file_names_str="-name '${l_file_names[$l_file_name_idx]}' "
        else
            l_file_names_str="${l_file_names_str} -o -name '${l_file_names[$l_file_name_idx]}'"
        fi

        let l_file_name_idx=$l_file_name_idx+1
    done

    # prevent * char expand function
    local l_cmd_str=$(printf "find ./ -type f %s\n" "${l_file_names_str}")

    local l_search_files=$(
        eval "$l_cmd_str"
    )

    if [ -z "${l_search_files}" ]  
    then
        printf "Cannot find any file!\n"
        return 0
    fi


    l_exclude_path_idx=0

    while [ "$l_exclude_path_idx" -lt "${#l_exclude_paths[@]}" ]
    do
        if [ -z "${l_exclude_paths[$l_exclude_path_idx]}" ]  
        then
            break
        fi

        l_search_files=$(
            printf "%s\n" "${l_search_files}" | \
            sed -n -e '/\/'"${l_exclude_paths[$l_exclude_path_idx]}"'\//!p'
        )
        
        let l_exclude_path_idx=$l_exclude_path_idx+1
    done

    if [ -z "${l_search_files}" ]  
    then
        printf "Cannot find any file after exclude specified folder names!\n"
        return 1
    fi


    local tmp_idx=0
    while read -r tmp_file_path_new
    do
        # printf "%s\n" "${tmp_file_path}"
        searchSingleFile "${tmp_file_path_new}" "${l_pattern_strs[0]}"
        let tmp_idx=$tmp_idx+1
    done <<< "${l_search_files}"
}
