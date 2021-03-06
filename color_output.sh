#!/bin/bash
#===global var area==========
bold_red_color="\033[1;31m"
bold_white_color="\033[1;97m"
bold_yellow_color="\033[1;33m"
bold_blue_color="\033[1;4;34m"
bold_magenta_color="\033[1;35m"
bold_cyan_color="\033[1;30;48;5;85m"
bold_gray_color="\033[1;90m"

light_magenta_color="\033[95m"

bold_white_red_color="\033[1;97;41m"
bold_yellow_blue_color="\033[1;33;104m"
color_end_str="\033[0m"

sed_bold_white_red_color="\\\033[1;97;41m"
sed_light_magenta_color="\\\033[95m"
sed_color_end_str="\\\033[0m"

tmp_xml_start='<?xml version="1.0" encoding='
tmp_xml_end="<\/[^\/][^\/]*:Envelope>"

xml_key_ele_name_list_file="${shell_util_dir}/xml_key_ele_name_list.txt"
xml_key_ele_name_list=""

sep_str="###"
#===function methods==========
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

function getSedColorStr()
{
    local color_value="\\$1"
    local origin_str="$2"

    local end_str="\\${color_end_str}"
    
    printf "%s\n" "$(getColorStr "${color_value}" "${origin_str}" "${end_str}")"
}

function regMatchCheck()
{
    local checkStr="$1"
    local matchStr="$2"

    # checkStr=$(printf "%s\n" "${checkStr}" | awk '{print tolower($0)}')
    # matchStr=$(printf "%s\n" "${matchStr}" | awk '{print tolower($0)}')

    local checkRlt=$(printf "%s\n" "${checkStr}" | sed -n -e '/'"${matchStr}"'/p')

    if [ -n "${checkRlt}" ]
    then
        printf "1\n"
        return 0
    else
        printf "0\n"
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

function is_xml_line()
{
    local chk_str="$1"
    local pattern_str="$2"
    printf "%s\n" $(regMatchCheck "${chk_str}" "${pattern_str}")
    return 0

    local chk_rlt=$(printf "%s\n" "${chk_str}" | awk '{if($0~p_str){printf"%s\n","1"}else{printf"%s\n","0"}}' p_str="${pattern_str}")

    printf "%s\n" "${chk_rlt}"
}


function get_split_lines()
{
    local single_line="$1"
    local split_str="$2"

    printf "%s\n" "${single_line}" | \
    awk -F ''"${split_str}"'' '{for(i=1;i<=NF;i++)print $i}' | \
    sed -n -e '/^$/d;p;'
}

function getXmlColorLine()
{

    local tmp_origin_xml_line="$1"
    local tmp_xml_ele_str="$2"

    if  regMatchCheck "${tmp_origin_xml_line}" "<[^\/][^\/]*:${tmp_xml_ele_str}>" > /dev/null
    then
        printf "%s\n" "${tmp_origin_xml_line}" | \
        sed -n -e 's/\(<[^\/][^\/]*:'"${tmp_xml_ele_str}"'>\)\([^<][^<]*\)\(<\/[^\/][^\/]*:'"${tmp_xml_ele_str}"'>\)/'"$(getSedColorStr "${bold_blue_color}" "\1" )""$(getSedColorStr "${bold_yellow_color}" "\2")""$(getSedColorStr "${bold_blue_color}" "\3")"'/g;p;'
        return 0
    elif  regMatchCheck "${tmp_origin_xml_line}" "<[^\/][^\/]*:${tmp_xml_ele_str}\/>" > /dev/null
    then
        printf "%s\n" "${tmp_origin_xml_line}" | \
        sed -n -e 's/\(<[^\/][^\/]*:'"${tmp_xml_ele_str}"'\/>\)/'"$(getSedColorStr "${bold_blue_color}" "\1")"'/g;p;'
        return 0
    fi

    printf "\n"
    return 1
}

function getXmlMatchKeyEleName()
{
    local tmp_xml_line_str="$1"
    local tmp_xml_match_key_list="$2"

    local tmp_xml_ele_name=$(
        printf "%s\n" "${tmp_xml_line_str}" | \
        sed -n -e 's/.*<[^\/:][^\/:]*:\([a-zA-Z0-9_]*\).*/\1/gp;'
    )

    if [ -z "${tmp_xml_ele_name}" ]  
    then
        return 1
    fi


    if regMatchCheck "#${tmp_xml_match_key_list}#" "#${tmp_xml_ele_name}#" > /dev/null
    then
        printf "%s\n" "${tmp_xml_ele_name}"
        return 0
    fi

    printf "\n"
    return 1
}

function highlight_xml_line_str()
{
    local tmp_origin_xml_str="$1"
    local tmp_xml_key_chk_flg="0"

    while IFS='' read -r tmp_xml_line
    do
        tmp_xml_key_chk_flg="0"
        tmp_xml_ele_name=""

        if [ -n "${xml_key_ele_name_list}" ]  
        then
            tmp_xml_ele_name=$(
                printf "%s\n" "${tmp_xml_line}" | \
                sed -n -e 's/.*<[^\/:][^\/:]*:\([a-zA-Z0-9_]*\).*/\1/gp;'
            )

            if [ -n "${tmp_xml_ele_name}" ]  
            then
                if regMatchCheck "#${xml_key_ele_name_list}#" "#${tmp_xml_ele_name}#" > /dev/null
                then
                    tmp_xml_key_chk_flg="1"
                fi
            fi
        fi

        if [ "${tmp_xml_key_chk_flg}" = "0" ]
        then
            tmp_out_xml_line=$(getColorStr "${bold_magenta_color}" "${tmp_xml_line}")
        else
            tmp_out_xml_line=$(getXmlColorLine "${tmp_xml_line}" "${tmp_xml_ele_name}")
        fi
        
        printf "%b\n" "$(get_split_lines "${tmp_out_xml_line}" "${sep_str}")"

    done <<< "${tmp_origin_xml_str}"
}

function xml_add_other_color()
{
    local tmp_highlight_xml_str="$1"
    local tmp_add_bg_flg="1"
    local tmp_color_end_reg_str="\\033\[0m"

    while IFS=''  read -r tmp_xml_line
    do
        # check whether contain color escape string
        local tmp_check_rlt=$(regMatchCheck "${tmp_xml_line}" "${tmp_color_end_reg_str}")

        if [ "${tmp_check_rlt}" = "1" ]
        then
            # match
            printf "%s%s\n" "${color_end_str}" "${tmp_xml_line}"
            tmp_add_bg_flg="1"
        else
            # unmatch
            if [ "${tmp_add_bg_flg}" = "1" ]
            then
                printf "%s%s\n"  "${bold_magenta_color}" "${tmp_xml_line}"
                tmp_add_bg_flg="0"
            else
                printf "%s\n" "${tmp_xml_line}"
            fi
        fi
        
    done <<< "${tmp_highlight_xml_str}"

    if [ "${tmp_add_bg_flg}" = "1" ]
    then
        printf "%s\n" "${color_end_str}"
    fi

}

function xml_format_log_string()
{
    local tmp_log_str="$1"

    local xml_sep_str="@@@"

    if [ -z "${tmp_log_str}" ]
    then
        return 0
    fi

    local combine_one_line=$(
        printf "%s\n" "${tmp_log_str}" | \
        sed -n -e '/^[[:blank:]]*$/d;p;' | \
        awk '{printf"%s%s",$0,sep_str}' sep_str="${sep_str}"
    )

    ## if doesn't include xml element, return immediately
    if [ $(is_xml_line "${combine_one_line}" "${tmp_xml_start}") = "0" ]
    then
        printf "%s\n" "${tmp_log_str}"

        return 0
    fi

    local tmp_xml_str=$(
        printf "%s\n" "${combine_one_line}" | \
        sed -n -e 's/\(<!\[CDATA\[<?xml\)/\1'"  "'/g;p;' | \
        sed -n -e 's/\(.*\)'"${tmp_xml_start}"'\(.*\)\('"${tmp_xml_end}"'\)\(.*\)/\1'"${xml_sep_str}${tmp_xml_start}"'\2\3'"${xml_sep_str}"'\4/g;p;' | \
        sed -n -e 's/^'"${xml_sep_str}"'//g;p;' | \
        awk -F ''${xml_sep_str}'' '{for(i=1;i<=NF;i++)print $i}'
    )

    # printf "%s\n" "${tmp_xml_str}"

    # return 0

    while IFS='' read -r tmp_line
    do
        check_rlt=$(is_xml_line "${tmp_line}" "${tmp_xml_start}")

        if [ "${check_rlt}" = "1"  ] 
        then
            tmp_line=$(
                printf "%s\n" "${tmp_line}" | \
                sed -n -e 's/>[[:blank:]]*'"${sep_str}"'[[:blank:]]*</></g;p;' | \
                sed -n -e '/^$/d;p;'
            )
            tmp_out_xml_str=$(printf "%s\n" "$tmp_line" | xmllint --format -)

            highlight_xml_line_str "${tmp_out_xml_str}"

            # tmp_out_xml_str=$(highlight_xml_str "${tmp_out_xml_str}")
            # tmp_out_str=$(xml_add_other_color  "${tmp_out_xml_str}")
            # tmp_out_str=$(get_split_lines "${tmp_out_str}" "${sep_str}")
        else
            tmp_out_str=$(getColorStr "${bold_cyan_color}" "$(get_split_lines "$tmp_line" "${sep_str}")")
            printf "%b\n" "${tmp_out_str}"
        fi


    done <<< "${tmp_xml_str}"
}

function macro_xml_end_check()
{
    if [ "$(is_xml_line "${log_string}" "${tmp_xml_end}")" = "1" ]
    then
        pre_log_str=$(printf "%s\n%s\n" "${pre_log_str}" "${log_string}" | sed -n -e '/^$/d;p;')
        xml_format_log_string "${pre_log_str}"
        # pre_log_str=$(xml_format_log_string "${pre_log_str}")
        # printf "%b\n" "${pre_log_str}"
        find_xml_flg="0"
        pre_log_str=""
    else
        if [ -z "${pre_log_str}" ]
        then
            pre_log_str="${log_string}"
        else
            pre_log_str=$(printf "%s\n%s\n" "${pre_log_str}" "${log_string}")
        fi 
    fi
}

function macro_print_log_line()
{
    find_xml_flg=$(is_xml_line "${log_string}" "${tmp_xml_start}")

    if [ "${find_xml_flg}" = "0" ]
    then
        # false
        log_string=$(getColorStr "${bold_cyan_color}" "${log_string}")
        printf "%b\n" "${log_string}"
    else
        # true
        eval "macro_xml_end_check"
    fi

}

function xml_format_non_gch_event_msg()
{

    local tmp_log_str="${pre_log_str}"
    local tmp_combine_one_line=$(
        printf "%s\n" "${tmp_log_str}" | \
        sed -n -e '/^[[:blank:]]*$/d;p;' | \
        awk '{printf"%s%s",$0,sep_str}' sep_str="${sep_str}"
    )

    find_xml_flg="0"
    pre_log_str=""

    if [ $(is_xml_line "${tmp_combine_one_line}" "${tmp_xml_start}") = "0" ]
    then
        printf "%s\n" "${tmp_log_str}"
        return 0
    fi
    local xml_sep_str="#"
    local tmp_xml_str="$(
        printf "%s\n" "${tmp_combine_one_line}" | \
        sed -n -e 's/\(.*\)\('"${tmp_xml_start}"'.*<\/[^\/>][^\/>]*>\)\(.*\)/\1'"${xml_sep_str}"'\2'"${xml_sep_str}"'\3/g;p;'
    )"

    # printf "%s\n" "${tmp_xml_str}"
    # return 0

    while IFS="${xml_sep_str}" read -r tmp_head_part tmp_xml_part tmp_tail_part
    do
        local tmp_out_str=$(getColorStr "${bold_cyan_color}" "$(get_split_lines "${tmp_head_part}" "${sep_str}")")
        printf "%b\n" "${tmp_out_str}"
        # printf "%s\n" "${tmp_head_part}"
        local tmp_out_xml_str="$(printf "%s\n" "${tmp_xml_part}" | xmllint --format -)"
        # highlight_xml_line_str "${tmp_out_xml_str}"
        tmp_out_xml_str="$(
            getColorStr "${bold_magenta_color}" "${tmp_out_xml_str}"
        )"
        printf "%b\n" "${tmp_out_xml_str}"
        # printf "%b\n" "$(get_split_lines "${tmp_out_xml_line}" "${sep_str}")"

        tmp_out_str=$(getColorStr "${bold_cyan_color}" "$(get_split_lines "${tmp_tail_part}" "${sep_str}")")
        # tmp_out_str="$(get_split_lines "${tmp_tail_part}" "${sep_str}")"
        printf "%b\n" "${tmp_out_str}"
        break;
    done <<< "${tmp_xml_str}"

}

function color_log_line()
{
    local pre_log_str=""
    local find_xml_flg="0"
    while read -r log_level log_thread log_date log_time log_class_method log_line_start log_line_end log_string
    do
        new_log_level=$(color_log_level "${log_level}")

        if [ -n "${new_log_level}" ]
        then
            # deal with previous unprint xml data which is the call home event xml message
            if [ "${find_xml_flg}" = "1"  ]
            then
                xml_format_non_gch_event_msg
            fi
           
            ## valid format log msg
            log_thread=$(getColorStr "${bold_yellow_color}" "${log_thread}")
            log_date_time=$(getColorStr "${light_magenta_color}" "${log_date} ${log_time}")
            log_class_method="$(color_class_method "${log_class_method}")"
            log_line=$(getColorStr "${bold_magenta_color}" "${log_line_start} ${log_line_end}")

            printf "%b %b %b %b %b\n" "${new_log_level}" "${log_thread}" "${log_date_time}"  "${log_class_method}" "${log_line}"            
            # check log_string whether contain xml head
            eval "macro_print_log_line"
        else
            log_string="${log_level} ${log_thread} ${log_date} ${log_time} ${log_class_method} ${log_line_start} ${log_line_end} ${log_string}"
            log_string=$(
                printf "%s\n" "${log_string}" | \
                sed -n -e 's/'"$(printf "%b" "\r")"'//g;p;' | \
                sed -n -e 's/[[:blank:]][[:blank:]][[:blank:]]*/ /g;p;'
            )

            # printf "%s\n" "${log_string}"
            if [ "${find_xml_flg}" = "1" ]
            then
                eval "macro_xml_end_check"
            else
                eval "macro_print_log_line"
            fi
        fi
    done
}

function sda_color_log_line()
{
    local tmp_print_log_line
    while IFS='' read -r tmp_sda_log_line
    do
        if regMatchCheck "${tmp_sda_log_line}" "^[[:blank:]]*INFO" > /dev/null
        then
            # log header line
            tmp_print_log_line=$(
                getColorStr "${bold_blue_color}" "${tmp_sda_log_line}"
            )
        else
            # log message
            if regMatchCheck "${tmp_sda_log_line}" "^>>>" > /dev/null
            then
                tmp_print_log_line=$(
                    getColorStr "${bold_white_red_color}" "${tmp_sda_log_line}"
                )
            elif regMatchCheck "${tmp_sda_log_line}" "^<<<" > /dev/null
            then
                tmp_print_log_line=$(
                    getColorStr "${bold_yellow_blue_color}" "${tmp_sda_log_line}"
                )
            else
                tmp_print_log_line=$(
                    getColorStr "${bold_magenta_color}" "${tmp_sda_log_line}"
                )
            fi

        fi

        printf "%b\n" "${tmp_print_log_line}"
    done
}


function color_log_line_new()
{
    local pre_log_str=""
    local find_xml_flg="0"
    while read -r log_level log_category log_thread log_date log_time log_class_method log_line_start log_line_end log_string
    do
        new_log_level=$(color_log_level "${log_level}")
       
        if [ -n "${new_log_level}" ]
        then
           
            ## valid format log msg
            log_category=$(getColorStr "${light_magenta_color}" "${log_category}")
            log_thread=$(getColorStr "${bold_gray_color}" "${log_thread}")
            log_date_time=$(getColorStr "${light_magenta_color}" "${log_date} ${log_time}")
            log_class_method="$(color_class_method "${log_class_method}")"
            log_line=$(getColorStr "${bold_magenta_color}" "${log_line_start} ${log_line_end}")

            printf "%b %b %b %b %b %b\n" "${new_log_level}" "${log_category}" "${log_thread}" "${log_date_time}"  "${log_class_method}" "${log_line}"            
            # check log_string whether contain xml head
            eval "macro_print_log_line"
        else
            log_string="${log_level} ${log_category} ${log_thread} ${log_date} ${log_time} ${log_class_method} ${log_line_start} ${log_line_end} ${log_string}"

            if [ "${find_xml_flg}" = "1" ]
            then
                eval "macro_xml_end_check"
            else
                eval "macro_print_log_line"
            fi
        fi
    done
}

function color_log_line_old()
{
    local pre_log_str=""
    while read -r log_level log_thread log_date log_time log_class_method log_line_start log_line_end log_string
    do
        new_log_level=$(color_log_level "${log_level}")
       
        if [ -n "${new_log_level}" ]
        then
            if [ -n "${pre_log_str}" ]
            then
                pre_log_str=$(xml_format_log_string "${pre_log_str}")
                pre_log_str=$(getColorStr "${bold_cyan_color}" "${pre_log_str}")
                printf "%b\n" "${pre_log_str}"
                pre_log_str=""
            fi
            
            ## valid format log msg
            log_thread=$(getColorStr "${bold_gray_color}" "${log_thread}")
            log_date_time=$(getColorStr "${bold_blue_color}" "${log_date} ${log_time}")
            log_class_method="$(color_class_method "${log_class_method}")"
            log_line=$(getColorStr "${bold_magenta_color}" "${log_line_start} ${log_line_end}")

            # log_string=$(getColorStr "${bold_cyan_color}" "${log_string}")
            log_string=$(xml_format_log_string "${log_string}")

            log_string=$(getColorStr "${bold_cyan_color}" "${log_string}")
            ## todo xml content format

            printf "\n%b %b %b %b %b\n%b\n" "${new_log_level}" "${log_thread}" "${log_date_time}"  "${log_class_method}" "${log_line}" "${log_string}"            
        else
            log_string="${log_level} ${log_thread} ${log_date} ${log_time} ${log_class_method} ${log_line_start} ${log_line_end} ${log_string}"

            if [ -z "${pre_log_str}" ]
            then
                pre_log_str="${log_string}"
            else
                pre_log_str=$(printf "%s\n%s\n" "${pre_log_str}" "${log_string}")
            fi 

        fi
    done
}



function color_log()
{
    # local opt_str="nf:"
    # while getopts "${opt_str}" tmp_opt
    # do
    #     case "${tmp_opt}" in
    #         f) tmp_xml_key=$OPTARG
    #             ;;
    #         n) tmp_x="1"
    #             ;;
    #         *) return 1;;
    #     esac
    # done

    # printf "%s\n" "$OLDPWD"
    # return 0

    if [ -e "${xml_key_ele_name_list_file}" ]
    then
        xml_key_ele_name_list=$(
            cat "${xml_key_ele_name_list_file}" | \
            sed -n -e '/^#/!p' | \
            awk '{printf"%s#",$0}END{printf"\n"}'
        )
    fi

    local log_file_path="$1"

    if [ -n "${log_file_path}" ]
    then
        tail -fn 1000 "${log_file_path}" | \
        sed -n -e 's/Test worker/Test_worker/g;p;' | \
        color_log_line
    else
        color_log_line
    fi
}

function sda_color_log()
{
    local log_file_path="$1"

    if [ -n "${log_file_path}" ]
    then
        tail -fn 1000 "${log_file_path}" | \
        sda_color_log_line
    else
        sda_color_log_line
    fi
}




function cat_log()
{
    local log_file_path="$1"

    if [ -n "${log_file_path}" ]
    then
        cat "${log_file_path}" | \
        color_log_sda_line
    else
        color_log_sda_line
    fi
}

function color_sed()
{
    local reg_pattern_str="$1"
    if [ -z "${reg_pattern_str}"  ]
    then
        return 0
    fi

    # printf "%s\n" "${reg_pattern_str}"
    while IFS='' read -r tmp_line
    do
        # printf "%s\n" "${tmp_line}" | \
        # sed -n -e '/'"${reg_pattern_str}"'/{
        #     s/'"${reg_pattern_str}"'/'$(getColorStr "${sed_bold_white_red_color}" "${reg_pattern_str}" "${sed_color_end_str}")'/g;
        #     p;
        # }' | \
        # awk '{cmd="printf \"%b\\n\"  \""$0"\"";system(cmd);close(cmd)}'
        # tmp_rlt_list=$(printf "%s\n" "${tmp_line}" | \
        # sed -n -e '/'"${reg_pattern_str}"'/{
        #     s/.*\('"${reg_pattern_str}"'\).*/&&\1/g;
        #     p;
        # }' | sort | uniq)



        tmp_rlt=$(
            printf "%s\n" "${tmp_line}" | \
            sed -n -e '/'"${reg_pattern_str}"'/{
                s/\('"${reg_pattern_str}"'\)/'$(getColorStr "${sed_bold_white_red_color}" "\1" "${sed_color_end_str}")'/g;
                s/\\n/###/g;
                p;
            }'
        )

        if [ -n "${tmp_rlt}" ] 
        then
            echo -e "${tmp_rlt}" | \
            sed -n -e 's/###/\\n/g;p;'
            # printf "%b\n" "${tmp_rlt}" 
        fi
    done
}

function remove_color()
{
    local ESC="`echo -e '\033'`"
    local ES1="${ESC}""\[""[0-9][0-9]*[;0123456789]*m"

    while read -r tmp_line
    do
        printf "%s\n" "${tmp_line}" | \
        sed -n -e "s/${ES1}//g;p;" 
    done
}

function color_file_path()
{
    while read -r tmp_file_path
    do
            
        # if [ ! -e "${tmp_file_path}" ]
        # then
        #     printf "%s\n" "${tmp_file_path}"
        #     continue
        # fi
    
        printf "%s\n" "${tmp_file_path}" | \
        sed -n -e 's/\([^\/][^\/]*\.jar\)/'"$(getColorStr ${sed_bold_white_red_color} "\1" "${sed_color_end_str}")"'/g;p;' | \
        sed -n -e 's/\(\/\)/'"$(getColorStr ${sed_light_magenta_color} "\1" "${sed_color_end_str}")"'/g;p;' 
    done
}

function getColorVarList()
{
    # set -x
    local tmp_color_var_list=$(
        cat "${shell_util_dir}/color_output.sh" | \
        sed -n -e '/="[^m][^m]*m"$/p' | \
        sed -n -e '/[[:blank:]]/!p'
    )

    local tmp_no=1;
    local l_print_fmt="%-4s%-30s%-30s\n"
    
    # print header string
    local l_header_line=$(printf "${l_print_fmt}" "No." "Color_Name." "Color_Value." | \
    sed -n -e 's/\([a-zA-Z_\.][a-zA-Z\.]*\)/'"$(getSedColorStr "${bold_cyan_color}" "\1")"'/g;p;' )

    printf "%b\n" "${l_header_line}"

    printf "$(printf "%s\n" "${l_print_fmt}" | sed -n -e 's/-/0/g;p;')" " " " " " " | sed -n -e 's/0/=/g;p;'

    # print color list
    while IFS="=" read -r tmp_color_var_name tmp_color_var_value
    do
        tmp_out_color_var_value=$(printf "%s\n" "${tmp_color_var_value}" | sed -n -e 's/"//g;p;' | sed -n -e 's/\\/#/g;p;')
        tmp_line_color=$(printf "%s\n" "${tmp_color_var_value}" | sed -n -e 's/"//g;p;' | sed -n -e 's/\\//g;p;')

        # 1. format it in printf firstly, thne use sed to add the color attribute
        tmp_line_str=$(
            printf "${l_print_fmt}" "${tmp_no}." "${tmp_color_var_name}" "${tmp_out_color_var_value}" | \
            sed -n -e 's/\([a-zA-Z_]*color[a-zA-Z_]*\)/\\'"$(getColorStr ${tmp_line_color} "\1" "${sed_color_end_str}")"'/g;p;'
        )
        
        printf "%b\n" "${tmp_line_str}" | sed -n -e 's/#/\\/g;p;'

        printf "$(printf "%s\n" "${l_print_fmt}" | sed -n -e 's/-/0/g;p;')" " " " " " " | sed -n -e 's/0/-/g;p;'

        let tmp_no=$tmp_no+1

    done <<< "${tmp_color_var_list}"

}

function getColorVarList_old()
{
    # set -x
    local tmp_color_var_list=$(
        cat "${shell_util_dir}/color_output.sh" | \
        sed -n -e '/="[^m][^m]*m"$/p' | \
        sed -n -e '/[[:blank:]]/!p'
    )

    local tmp_no=1;
    while IFS="=" read -r tmp_color_var_name tmp_color_var_value
    do
        tmp_color_var_value=$(printf "%s\n" "${tmp_color_var_value}" | sed -n -e 's/"//g;p;')
        tmp_color_var_name=$(printf "%b\n" "${tmp_color_var_value}${tmp_color_var_name}${color_end_str}" | sed -n -e 's/\\//g;p;')
        
        printf "%-4s%-30s%-30b\n" "${tmp_no}" "${tmp_color_var_value}" "${tmp_color_var_name}" 
        let tmp_no=$tmp_no+1
    done <<< "${tmp_color_var_list}"

}

function getEventXMLEleList()
{
    local tmp_file_path="$1"
    
    local tmp_ch_eles[1]="ch:EventTime"
    local tmp_ch_eles[2]="ch:Type"
    local tmp_ch_eles[3]="ch:SubType"
    local tmp_ch_eles[4]="ch:Name"
    local tmp_ch_eles[5]="ch:Contact"

    local tmp_sed_str_part_1=""
    local tmp_sed_str_part_2=""
    local tmp_str1=""
    local tmp_str2=""
    local tmp_index=0
    local tmp_color_str=""
    local tmp_ele=""

    local tmp_sep_line="********************************************************************************"

    for tmp_ele in "${tmp_ch_eles[@]}"
    do

        tmp_str1="h;s/.*\(<${tmp_ele}>\)\(.*\)\(<\/${tmp_ele}>\).*/$(getSedColorStr "${bold_blue_color}" "\1")$(getSedColorStr "${bold_yellow_color}" "\2")$(getSedColorStr "${bold_blue_color}" "\3") ##/gp;x;"
        tmp_str2="h;s/.*\(<${tmp_ele}\/>\).*/$(getSedColorStr "${bold_white_red_color}" "\1")##/p;x;"
        tmp_sed_str_part_1="${tmp_sed_str_part_1}${tmp_str1}${tmp_str2}"

        tmp_color_str="${tmp_color_str}color_sed ${tmp_ele} | "
    done

    local tmp_sed_cmd_str="printf \"%b\\n\" \"\$(sed -n -e '{${tmp_sed_str_part_1}}')\" | awk '{printf\"%s\",\$0}END{printf\"\\n\"}' | awk -F '##' '{for(i=1;i<=NF;i++)print \$i}' "

    # printf "%s\n" "${tmp_sed_cmd_str}"
    # return 0

    while read -r tmp_line
    do
        local tmp_cmd="printf \"%s\\n\" \"${tmp_line}\" | ${tmp_sed_cmd_str}"
        # printf "%s\n" "${tmp_cmd}"
        local tmp_rlt_str=$(
            eval "${tmp_cmd}"
        )

        if [ -n "${tmp_rlt_str}" ]
        then
            let tmp_index=$tmp_index+1
            printf "%s\n[%s]\n%s\n" "${tmp_sep_line}" "${tmp_index}" "${tmp_rlt_str}"
        fi
    done
    
}

function getMissNumber()
{
    local tmp_expect_num="$1"
    local tmp_check_numbers=""
    
    while read -r tmp_line
    do
        tmp_check_numbers=$(
            printf "%s\n%s\n" "${tmp_check_numbers}" "${tmp_line}"
        )
    done

    printf "%s\n" "${tmp_check_numbers}" | \
    sed -n -e '/^$/d;p;' | \
    sed -n -e 's/.*chbin\(.*\)@cisco.com/\1/g;p;' | \
    awk 'BEGIN{current=1;start=1;}{current=int($0);while(start<current){print start++}start++;}END{while(start<=end){print start++}}' end="${tmp_expect_num}"
}

function getEventXMLEleList_old()
{
    local tmp_file_path="$1"
    
    local tmp_ch_eles[1]="ch:EventTime"
    local tmp_ch_eles[2]="ch:Type"
    local tmp_ch_eles[3]="ch:SubType"
    local tmp_ch_eles[4]="ch:Name"
    local tmp_ch_eles[5]="ch:Contact"

    local tmp_sed_str_part_1=""
    local tmp_sed_str_part_2=""
    local tmp_str1=""
    local tmp_str2=""
    local tmp_index=0
    local tmp_color_str=""
    local tmp_ele=""

    for tmp_ele in "${tmp_ch_eles[@]}"
    do
        let tmp_index=$tmp_index+1
        tmp_str1=$(
            printf ".*\(<%s>.*<\/%s>\).*\n"  "${tmp_ele}" "${tmp_ele}"
        )
        tmp_str2=$(
            printf "\\%d##\n" "${tmp_index}"
        )

        if [ "${tmp_ele}" = "ch:SubType" ] 
        then
            tmp_str1=$(
                printf "%s\(<%s\>\).*\n"  "${tmp_str1}" "${tmp_ele}"
            )
            let tmp_index=$tmp_index+1
            tmp_str2=$(
                printf "%s\\%d##\n" "${tmp_str2}" "${tmp_index}"
            )
        fi
        tmp_sed_str_part_2="${tmp_sed_str_part_2}${tmp_str2}"
        tmp_sed_str_part_1="${tmp_sed_str_part_1}${tmp_str1}"
        tmp_color_str="${tmp_color_str}color_sed ${tmp_ele} | "
    done

    local tmp_sed_cmd_str=$(
        printf "sed -n -e 's/%s/%s/g;p;' | %s awk -F '##' '{for(i=1;i<=NF;i++)print\$i}' \n" "${tmp_sed_str_part_1}" "${tmp_sed_str_part_2}" "${tmp_color_str}"
    )

    printf "%s\n" "${tmp_sed_cmd_str}"
    # return 0

    while read -r tmp_line
    do
        tmp_cmd="printf \"%s\\n\" \"${tmp_line}\" | ${tmp_sed_cmd_str}"
        # printf "%s\n" "${tmp_cmd}"
        eval "${tmp_cmd}"
    done
    
}

function strPatternHighlight()
{
    local tmp_str_patterns="$#"

    if [ "${tmp_str_patterns}" -eq 0 ]
    then
        printf "Please input the Highlight Pattern Strings!\n"
        return 1
    fi

    local tmp_str_pattern_list=$(printf "%s\n" $@)

    ## build the sed color match string
    local tmp_sed_strs=""
    while read -r tmp_pattern
    do
        # printf "%s\n" "${tmp_pattern}"
        tmp_sed_strs="${tmp_sed_strs}s/\(${tmp_pattern}\)/$(getSedColorStr ${bold_white_red_color} "\1")/g;"
    done <<< "${tmp_str_pattern_list}"
    # "$(printf "%s\n" "${tmp_str_patterns}" | awk '{for(i=1;i<=NF;i++)print $i}')"

    # printf "%s\n" "${tmp_sed_strs}"

    while IFS='' read -r tmp_line
    do
        tmp_line=$(
            printf "%s\n" "${tmp_line}" | sed -n -e 's/\($[1-9]\)/\\\1/g;p;'
        )
        local tmp_cmd="printf \"%b\n\" \"\$(printf \"%s\n\" \""${tmp_line}"\" | sed -n -e '"${tmp_sed_strs}"p;')\""
        # printf "%s\n" "${tmp_cmd}"
        eval "${tmp_cmd}"
    done


    
}
#=== export section : used to export these function==========
export -f getColorStr
export -f regMatchCheck
export -f color_log_level
export -f color_class_method
export -f is_xml_line
export -f get_split_lines
export -f xml_format_log_string
export -f macro_xml_end_check
export -f macro_print_log_line
export -f color_log_line
export -f color_log_line_old
export -f color_log
export -f cat_log
export -f color_sed
export -f remove_color
export -f color_file_path
export -f getEventXMLEleList
