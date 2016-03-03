#!/bin/bash

#Desc: include all function about sftp;
#Author : chbin
#Date: Sun Dec 13 20:58:02 CST 2015


# get user name and pwd for sftp server
function getsftpLoginInfo()
{
    local checkRetry_cnt=10
    local tmp_cnt=1

    while [ "${tmp_cnt}" -le "${checkRetry_cnt}" ]
    do
    
        read -p "Enter the sftp user name :" sftp_user_name_local
        read -p "Enter the sftp pwd : " -s sftp_user_pwd_local

        printf "\n"

        sftp_user_name="${sftp_user_name_local}"
        sftp_user_pwd="${sftp_user_pwd_local}"

        # check the login info with the expect
        cd "${shell_util_dir}";expect checkSftpLoginInfo.exp "${sftp_user_name_local}" "${sftp_user_pwd_local}"

        if [ "$?" -gt 0 ]
        then
            printf "Check login failded!\n"
        else
            printf "Pass Login check!\n"
            return 0
        fi

        let tmp_cnt=$((tmp_cnt+1))
    done
    return 1
}
