#!/bin/bash

#Desc: include all function about sftp;
#Author : chbin
#Date: Sun Dec 13 20:58:02 CST 2015

# validate the sftp login user name and password
function verifySftpLoginInfo()
{
    local l_sftp_user_name="$1"
    local l_sftp_user_pwd="$2"

    # check the login info with the expect
    expect "${shell_util_dir}/"checkSftpLoginInfo.exp "${l_sftp_user_name}" "${l_sftp_user_pwd}"

    if [ "$?" -gt 0 ]
    then
        return 1
    fi
    
    return 0
}

# get user name and pwd for sftp server
function sftpTaskEngine()
{
    local l_task_func_name="$1"
    local l_task_func_parameters="$2"

    local checkRetry_cnt=10
    local tmp_cnt=1

    local l_sftp_user_name_input=""
    local l_sftp_user_pwd_input=""
    local l_verify_rlt=""

    while [ "${tmp_cnt}" -le "${checkRetry_cnt}" ]
    do
    
        read -p "Enter the sftp user name :" l_sftp_user_name_input
        read -p "Enter the sftp pwd : " -s l_sftp_user_pwd_input

        printf "\n"

        if ! verifySftpLoginInfo "${l_sftp_user_name_input}" "${l_sftp_user_pwd_input}" > /dev/null 2>&1
        then
            printf "Check login failded!\n"
        else
            printf "Pass Login check!\n"
            
            if [ -n "${l_task_func_name}" ]  
            then
                # execute the input task function
                eval "${l_task_func_name} ${l_sftp_user_name_input} ${l_sftp_user_pwd_input} ${l_task_func_parameters}"
            fi
            return 0
        fi

        let tmp_cnt=$((tmp_cnt+1))
    done
    return 1
}



function sftpUploadFile()
{
    local tmp_upload_file_path="$1"

    if [ -z "${tmp_upload_file_path}" ]  
    then
        printf "Please input the upload file path info!\n"
        return 1
    fi

    if [ ! -e "${tmp_upload_file_path}" ]
    then
        printf "Invalid file path:%s\n" "${tmp_upload_file_path}"
        return 1
    fi
    
    sftpTaskEngine "expect '${shell_util_dir}/sftp_upload.exp' " "${tmp_upload_file_path}"

}
