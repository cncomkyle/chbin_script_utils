#!/bin/bash

#Desc: Covernt script record text into expect code which can be help to replay.
#Author : chbin
#Date : Mon May 30 12:57:46 CST 2016

function writeToFile()
{
    local tmp_write_str="$1"
    local tmp_write_file="$2"

    printf "%s\n" "${tmp_write_str}" >> "${tmp_write_file}"
}

function genReplayScript()
{
    local tmp_input_file="$1"
    local tmp_output_file="$2"
    local tmp_head_str="$3"
    local tmp_start_cmd="$4"

    if [ "$#" -ne 4 ]
    then
        printf "Please input the {input_file_path}  {output_file_path} {head_str} {start_cmd}\n"
        return 1
    fi

    if [ ! -e "${tmp_input_file}" ]
    then
        printf "The %s does't exit!\n" "${tmp_input_file}"
        return 1
    fi

    if [ -e "${tmp_output_file}" ]
    then
        rm -f "${tmp_output_file}"
    fi

    ## initial spawn cmd
    # writeToFile "set send_human {.05 .05 .05 .05 .06}" "${tmp_output_file}"
    local tmp_spawn_cmd="spawn ${tmp_start_cmd}"
    writeToFile "${tmp_spawn_cmd}" "${tmp_output_file}"
    ## set time out to -1
    local tmp_timeout_set_cmd="set timeout -1"
    writeToFile "${tmp_timeout_set_cmd}" "${tmp_output_file}"
    ## last interact cmd
    local tmp_interact_cmd="interact"

    ## send cmd list
    local tmp_send_cmd_list=$(
        cat "${tmp_input_file}" | {
            ## replace escape char to @@@ and add linenum ahead of each line
            sed -n -e 's/'"$(printf "%b" "\033")"'\[/@@@/g;p;' | \
            awk '{printf"%d#%s\n",NR,$0}'
        } | {
            ## get the only head by head_str as gvd-java
            sed -n -e '/'"${tmp_head_str}"'/p;'
        } | {
            ## remove the ^C char
            sed -n -e 's/'"$(printf "%b" "\x03")"'//g;p;'
        } | {
            ## change $[head_str]#quitxxx to ${head_str}#quit\r
            sed -n -e '/@@@[0-9]*J/!p' | \
            sed -n -e 's/\(.*'"${tmp_head_str}"'#quit\).*/\1\\r/g;p;'
        } | {
            ## delete the line contain cursor position contral escape char
            sed -n -e '/@@@[0-9]*[0-9;]*H/!p' 
        } | {
            ## replace tab char to \t
            # sed -n -e 's/'"$(printf "%b" "\t\x0d\x0a")"'/\\t/g;p;'
            # delete the line contain tab
            sed -n -e '/'"$(printf "%b" "\t")"'/!p'
        } | {
            ## replace the delete char to \b
            sed -n -e 's/'"$(printf "%b" "\x7f\x08")"'/\\b/g;p;'
        } | {
            sed -n -e 's/'"$(printf "%b" "\x7f")"'/\\b/g;p;'
        } | {
            ## replace the \r to ### for later use
            sed -n -e 's/'"$(printf "%b" "\r")"'/###/g;p;' 
        } | {
            ## delete the blank line
            sed -n -e '/'"${tmp_head_str}"'[^#]*##*[[:blank:]]*$/!p;'
        } 
    )

    # printf "%s\n" "${tmp_send_cmd_list}"
    # return 0

    local tmp_expect="expect \"${tmp_head_str}\""
    local tmp_new_line_cmd="send \"\r\""
    local tmp_send_cmd=""
    local tmp_comment_str=""
    local tmp_timestamp_str="\033\[1;4;31m[timestamp -format %X]\033\[0m"
    local tmp_next_cmd_str="\033\[1;97;41mVVV\033\[0m"

    local tmp_start_date_str="send_user \"${tmp_next_cmd_str}\033\[1;35m start next cmd at time : ${tmp_timestamp_str} \033\[0m${tmp_next_cmd_str}\""

    local tmp_finish_date_str="send_user \"\n\033\[1;97;41mVVV\033\[0m\033\[1;35m Finish above cmd at time : ${tmp_timestamp_str} \033\[0m\033\[1;97;41mVVV\033\[0m\n\""

    local tmp_print_date_cmd="$(printf "%s\n%s\n%s\n" "${tmp_expect}" "${tmp_start_date_str}" "${tmp_new_line_cmd}")"

    ## create the expect & send code body

    while IFS="#" read -r tmp_line_num tmp_prompt tmp_cmd
    do
        local nextLineNum=$(($tmp_line_num+1))

        local nextLineStr=$(
            cat "${tmp_input_file}" | \
            sed -n -e ''"${nextLineNum}"'p'
        )

        if [ -n "${nextLineStr}" ]
        then
            local tmp_empty_check_rlt=$(
                printf "%s\n" "${nextLineStr}" | \
                sed -n -e '/^'"${tmp_head_str}"'[^#]*#$/p'
            )

            if [ -n "${tmp_empty_check_rlt}" ]
            then
                continue
            fi
        fi

        # printf "%s\n" "${tmp_line_num}"
        local tmp_new_cmd=$(
            printf "%s\n" "${tmp_cmd}" | \
            sed -n -e 's/###/\\r/g;p;' | \
            sed -n -e 's/\\r\\r*/\\r/g;p;'
        )

        tmp_send_cmd="send \"${tmp_new_cmd}\""
        tmp_comment_str="#>>> ${tmp_prompt}#${tmp_new_cmd}"
        
        printf "\n%s\n%s\n%s\n%s\n\n" "${tmp_print_date_cmd}"  "${tmp_expect}" "${tmp_comment_str}" "${tmp_send_cmd}"  >> "${tmp_output_file}" 
        
    done <<< "${tmp_send_cmd_list}"

    # last section interact cmd
    writeToFile "${tmp_interact_cmd}" "${tmp_output_file}"
    writeToFile "${tmp_finish_date_str}" "${tmp_output_file}"
}
