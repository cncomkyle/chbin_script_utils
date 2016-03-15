#!/bin/bash

#Desc: Maven Util Shell Script
#Author : chbin

function mvnDepJarList()
{
    local pom_file_path="$1"
    local mvn_cmd="mvn -U dependency:build-classpath"
    if [ -n "${pom_file_path}" ]
    then
        mvn_cmd="${mvn_cmd} -f ${pom_file_path}"
    fi
    local mvn_dep_jar_list=$(eval "${mvn_cmd}" | \
    sed -n -e '/http:/!p' | \
    sed -n -e '/\.jar/p' | \
    awk -F ':' '{for(i=1;i<=NF;i++)print $i}' | \
    color_file_path)

    printf "%b\n" "${mvn_dep_jar_list}"
}

function genStrFromPattern()
{
    local pattern_string="$1"
    local project_name_string="$2"
    local version_info_string="$3"

    local rlt_string=$(printf "%s" "${pattern_string}" | sed -n -e 's/{project_name}/'"${project_name_string}"'/gp' | sed -n -e 's/{version_info}/'"${version_info_string}"'/gp')

    printf "%s\n" "${rlt_string}"

    # return "${rlt_string}"
}
# download gch sample projet zip file
# function dgchsp()
# {
#     local ver_str="$1"
    
#     if [  -z "${ver_str}"  ]
#     then
#         printf "Please input the right version number !\n"
#         return 1
#     fi

#     local maven_repo_url_pattern="http://engci-maven.cisco.com/artifactory/cstg-gch-java-group/com/gch/callhome/{project_name}/{version_info}"

#     proj_nms[0]="pd_demo_with_gch_ipc"
#     proj_nms[1]="gch_process_with_ipc"
#     proj_nms[2]="pd_demo_with_gch_lib"

#     for tmp_proj_nm in "${proj_nms[@]}"
#     do
#         local zip_file_nm="${tmp_proj_nm}-${ver_str}-project.zip"
#         local download_url=$(genStrFromPattern "${maven_repo_url_pattern}/${zip_file_nm}" "${tmp_proj_nm}" "${ver_str}")
#         printf "Begin download %s\n" "${download_url}"
#         wget "${download_url}" > /dev/null 2>&1

#         if [ "$?" -gt "0" ] 
#         then
#             printf "Fail to download from %s\n" "${download_url}"
#         fi

#         if [ -e "${zip_file_nm}" ]
#         then
#             printf "Begin unzip %s\n" "${zip_file_nm}"
#             unzip "${zip_file_nm}" > /dev/null 2>&1
#         else
#             printf "Fail to download file %s\n" "${zip_file_nm}"
#             return 1
#         fi
#     done
# }

function checkISNum()
{
    local tmp_chk_str="$1"

    local tmp_chk_rlt=$(
        printf "%s\n" "${tmp_chk_str}" | \
        sed -n -e 's/^[[:blank:]]*\([0-9][0-9]*\)[[:blank:]]*$/\1/gp;'
    )

    if [ -z "${tmp_chk_rlt}" ]  
    then
        printf "\n"
        return 1
    else
        printf "%s\n" "${tmp_chk_rlt}"
        return 0
    fi
}

function getArrayItemValue()
{
    local tmp_array_nm="$1"
    local tmp_array_idx="$2"

    eval 'printf "%s\n" ${'"${tmp_array_nm}"'['"${tmp_array_idx}"']} '
}


function getSelectOptionValue()
{
    local tmp_opt_array_nm="$1"
    local tmp_opt_array_size="$2"
    local tmp_opt_prompt_str="$3"


    if [ "$#" -lt 3 ]
    then
        printf "Please input {option array name} {option array size} {prompt string}\n"
        return 1
    fi

    local tmp_back_pre_menu_flg="$4"

    if [ -z "${tmp_back_pre_menu_flg}" ]  
    then
        tmp_back_pre_menu_flg="0"
    fi

    local tmp_op_step_num="$5"


    local tmp_select_opt_list=$(
        eval 'printf "%s\n" "${'$tmp_opt_array_nm'[@]}"' | \
        awk '{printf"[%d].%s\n",FNR,$0}'
    )

    if [ "${tmp_back_pre_menu_flg}" = "1"  ]
    then
        tmp_select_opt_list=$(
            printf "%s\n%s\n" "[0].Back To Previous Menu." "${tmp_select_opt_list}"
        )
    fi

    tmp_select_opt_list=$(
        printf "%s\n" "${tmp_select_opt_list}" | \
        color_sed "\[.*\]"
    )

    if [ -z "${tmp_select_opt_list}" ]  
    then
        printf "Cannot get opt List value, maybe the array name wrong!\n"
        return 1
    fi


    # local tmp_prompt_str_1=$(getColorStr "${bold_red_color}" "Please select ${tmp_opt_prompt_str} from below list:")
    local tmp_break_line="================================================================================"
    tmp_break_line=$(getColorStr "${light_magenta_color}" "${tmp_break_line}")

    local tmp_prompt_str_1=$(printf "%s\n" "Please select ${tmp_opt_prompt_str} from below list:" | color_sed "${tmp_opt_prompt_str}")
    
    if [ -n "${tmp_op_step_num}" ]
    then
        tmp_prompt_str_1=$(
            printf "%s\n%s\n" "$(getColorStr "${bold_magenta_color}" ">>>Step#${tmp_op_step_num}")" "${tmp_prompt_str_1}"
        )
    fi

    local tmp_prompt_str_3=$(printf "%s\n" ">>> Input the [No]. Number value: " | color_sed "\[No\].")
    local tmp_prompt_str=$(printf "%b\n%b\n%b\n%b\n" "${tmp_break_line}"  "${tmp_prompt_str_1}" "${tmp_select_opt_list}"  "${tmp_prompt_str_3}")

    local tmp_case_str="^[1-9]*$"


    while TRUE
    do
        local tmp_chk_flg="0"
        read -e -p "${tmp_prompt_str}" tmp_select_opt_no

        ## check the validation of the select opt no, must be number
        tmp_select_opt_no=$(
            checkISNum "${tmp_select_opt_no}"
        )

        if [ "$?" -eq "0" ] 
        then

            if [ "${tmp_back_pre_menu_flg}" = "1" ] &&  [ "${tmp_select_opt_no}" = "0" ]
            then
                printf "%d\n" "-1"
                return 0
            fi
            
            tmp_select_opt_value=$(eval 'printf "%s\n" "${'${tmp_opt_array_nm}'[@]}"' | sed -n -e ''${tmp_select_opt_no}'p') 

            if [ -z "${tmp_select_opt_value}" ]  
            then
                tmp_chk_flg="1"
            else
                let tmp_select_opt_no=$tmp_select_opt_no-1
                printf "%s\n" "${tmp_select_opt_no}"
                return 0
            fi
        else
            tmp_chk_flg="1"
        fi

        if [ "${tmp_chk_flg}" = "1"  ]
        then
            printf "Please input valid option No. Value!\n"
        fi

    done
}

function downloadGCHSampleProject()
{

    local tmp_publish_type="$1"
    local tmp_prj_name="$2"
    local tmp_prj_ver="$3"
    local tmp_save_path="$4"

    if [ "$#" -lt 4 ]
    then
        printf "Please input {project name} {project version} {save path}\n"
        return 1
    fi


    local maven_repo_url_pattern="http://engci-maven.cisco.com/artifactory/cstg-gch-java-{publish_type}/com/gch/callhome/{project_name}/{version_info}"

    local zip_file_nm="${tmp_prj_name}-${tmp_prj_ver}-project.zip"
    maven_repo_url_pattern=$(
        printf "%s\n" "${maven_repo_url_pattern}" | \
        sed -n -e 's/{publish_type}/'"${tmp_publish_type}"'/g;p'
    )
    local download_url=$(genStrFromPattern "${maven_repo_url_pattern}/${zip_file_nm}" "${tmp_prj_name}" "${tmp_prj_ver}")
    
    printf "Begin download %s from:\n%s\n" "${zip_file_nm}" "${download_url}" | \
    color_sed "${zip_file_nm}"
    $(cd "${tmp_save_path}"; wget "${download_url}" > /dev/null 2>&1)

    
    if [ "$?" -gt "0" ] 
    then
        printf "Fail to download from %s\n" "${download_url}"
        return 1
    fi

    if [ -e "${tmp_save_path}/${zip_file_nm}" ]
    then
        printf "Begin unzip %s\n" "${zip_file_nm}" | \
        color_sed "${zip_file_nm}"

        $(cd "${tmp_save_path}";unzip "${zip_file_nm}" > /dev/null 2>&1)

        printf "Please go to path %s to view %s source code\n" "${tmp_save_path}" "${tmp_prj_name}-${tmp_prj_ver}" | \
        color_file_path | \
        color_sed "${tmp_prj_name}-${tmp_prj_ver}"
    else
        printf "Fail to download file %s\n" "${zip_file_nm}"
        return 1
    fi
}

function clearGCHDownloadDir()
{
    local tmp_save_path="$1"

    if [ -e "${tmp_save_path}"  ]
    then
        rm -fr "${tmp_save_path}"
    fi

    mkdir -p "${tmp_save_path}"
}

function macroGetGCHSampleProject()
{
    local tmp_publish_type="$1"
    local tmp_version="$2"
    local tmp_prj_array_name="$3"
    local tmp_prj_array_size="$4"
    local tmp_save_folder_name="$5"

    local tmp_save_path="$PWD/GCH_Sample_Project/$(date +%Y_%m_%d)/${tmp_publish_type}/${tmp_version}/${tmp_save_folder_name}/"
    clearGCHDownloadDir "${tmp_save_path}"

    local tmp_index=0

    while [ "${tmp_index}" -lt "${tmp_prj_array_size}" ]
    do
        local tmp_prj_name=$(eval 'printf "%s\n" "${'$tmp_prj_array_name'['${tmp_index}']}"')
        downloadGCHSampleProject "${tmp_publish_type}" "${tmp_prj_name}" "${tmp_version}" "${tmp_save_path}"

        let tmp_index=$tmp_index+1
    done
   
}

function getGCHLibSampleProject()
{
    local tmp_publish_type="$1"
    local tmp_version="$2"
    local gch_lib_prj[0]="pd_demo_with_gch_lib"

    macroGetGCHSampleProject "${tmp_publish_type}" "${tmp_version}" "gch_lib_prj" "${#gch_lib_prj[@]}" "GCH_Lib"

    # local tmp_save_path="$PWD/GCH_Sample_Project/$(date +%Y_%m_%d)/${tmp_version}/GCH_Lib/"
    # clearGCHDownloadDir "${tmp_save_path}"

    # for tmp_prj_name in "${gch_lib_prj[@]}"
    # do
    #     downloadGCHSampleProject "${tmp_prj_name}" "${tmp_version}" "${tmp_save_path}"
    # done
}

function getGCHIPCSampleProject()
{
    local tmp_publish_type="$1"
    local tmp_version="$2"

    local gch_ipc_prj[0]="pd_demo_with_gch_ipc"
    local gch_ipc_prj[1]="gch_process_with_ipc"

    macroGetGCHSampleProject "${tmp_publish_type}" "${tmp_version}" "gch_ipc_prj" "${#gch_ipc_prj[@]}" "GCH_IPC"

}

function getGCHBothLibIPCSampleProject()
{
    local tmp_publish_type="$1"
    local tmp_version="$2"
    
    getGCHLibSampleProject "${tmp_publish_type}"  "${tmp_version}"
    getGCHIPCSampleProject "${tmp_publish_type}"  "${tmp_version}"
}

# TODO can not get to a good way to get the realease version publishcation time stamp!
# function getMVNLastUpdateTimeStr()
# {
# }



function getGCHComponentVersionList()
{
    local tmp_prj_name="$1"
    local tmp_publish_type="$2" # release/snapshot

    local maven_metadata_url_pattern="http://engci-maven-master.cisco.com/artifactory/cstg-gch-java-{publish_type}/com/gch/callhome/{project_name}/maven-metadata.xml"
    
    local tmp_maven_metadata_url=$(
        printf "%s\n" "${maven_metadata_url_pattern}" | \
        sed -n -e 's/{publish_type}/'"${tmp_publish_type}"'/g;p;' | \
        sed -n -e 's/{project_name}/'"${tmp_prj_name}"'/g;p;'
    )

    local tmp_maven_metadata_info=$(
        wget -qO - "${tmp_maven_metadata_url}" 2>&1
    )

    if [ "$?" -gt "0" ]
    then
        printf "Fail to get metadata info from %s\n!" "${tmp_maven_metadata_url}"
        return "${LINENO}"
    fi

    if [ -z "${tmp_maven_metadata_info}" ]  
    then
        printf "Empty metadata info from %s\n" "${tmp_maven_metadata_url}"
        return "${LINENO}"
    fi

    # local tmp_version_list=$(
    #     printf "%s\n" "${tmp_maven_metadata_info}" | \
    #     sed -n -e '/<version>/p' | \
    #     sed -n -e 's/.*<version>\([^<>]*\)<\/version>.*/\1/g;p;' | \
    #     tac 
    # )

    local tmp_version_list=$(
        printf "%s\n" "${tmp_maven_metadata_info}" | \
        sed -n -e 's/^[[:blank:]]*\(.*\)[[:blank:]]*$/\1/g;p;' | \
        awk '{printf"%s",$0}' | \
        sed -n -e 's/.*<versions>\(.*\)<\/versions>.*/\1/g;p;' | \
        sed -n -e 's/<version>//g;s/<\/version>/#/g;p;' | \
        awk -F '#' '{for(i=1;i<=NF;i++)print $i}' | \
        sed -n -e '/^$/d;p;' | \
        tac
    )

    printf "%s\n" "${tmp_version_list}"

    # get its last update time string
    # while read -r tmp_version_str
    # do
        
    # done <<< "${tmp_version_list}"

}



function getGCHVersion()
{
    local tmp_publish_type="$1"
    local tmp_step_hint_str="$2"

    local tmp_version_list=$(getGCHComponentVersionList "gch_core" "${tmp_publish_type}")

    if [ -z "${tmp_version_list}" ]  
    then
        printf "Cannot get %s GCH Version List, please check it!\n" "${tmp_publish_type}"
        return 1
    fi

    local tmp_version_no_list=$(
        printf "%s\n" "${tmp_version_list}" | \
        sed -n -e '1,5p' | \
        awk '{printf"No.[%d]    %s\n",FNR, $0}'         
    )

    tmp_version_list=$(
        printf "%s\n" "${tmp_version_list}" | \
        sed -n -e '1,5p'
    )


    local tmp_version_array[0]=""

    local tmp_version_array_idx=0
    while read -r tmp_version_line
    do
        eval 'tmp_version_array['$tmp_version_array_idx']='$tmp_version_line''
        let tmp_version_array_idx=$tmp_version_array_idx+1
    done <<< "${tmp_version_list}"

    local tmp_version_no=$(
        getSelectOptionValue "tmp_version_array" "${#tmp_version_array[@]}" "${tmp_publish_type} Version No." "1" "3 ${tmp_step_hint_str}"
    )

    if [ "${tmp_version_no}" = "-1" ]
    then
        printf "Back to Previous Menu!!!\n"
        return 1
    fi

    printf "%s\n" "$(getArrayItemValue "tmp_version_array" "${tmp_version_no}")"

    return 0
    
}

function getGCHPublishType()
{
    local tmp_step_hint_str="$1"
    
    local tmp_publish_types[0]="release"
    local tmp_publish_types[1]="snapshot"

    local tmp_publish_type=$(
        getSelectOptionValue "tmp_publish_types" "${#tmp_publish_types[@]}" "Publish Type" "1" "2 ${tmp_step_hint_str}"
    )

    if [ "${tmp_publish_type}" = "-1" ]
    then
        printf "Back to Previous Menu!!!\n"
        return 1
    fi
    
    printf "%s\n" "$(getArrayItemValue "tmp_publish_types" "${tmp_publish_type}")"

    return 0

}


function getGCHSampleProject()
{
    local gch_type[0]="Library"
    gch_type[1]="Process Server"
    gch_type[2]="All Above"

    local tmp_gch_type_index=0
    local tmp_gch_prj_index=0

    # local tmp_gch_type_list=$(
    #     printf "%s\n" "${gch_type[@]}" | \
    #     awk '{printf"No.[%s] %s\n",NR,$0}'            
    # )

    # step 1: select gch_type
    local tmp_steps_finish_flg="0"
    while TRUE
    do

        tmp_gch_type_no=$(
            getSelectOptionValue "gch_type" "${#gch_type[@]}" "GCH Type" "0" "1" 
        )

        if [ "$?" -gt "0" ]
        then
            printf "%b\n" "$(getColorStr "${bold_red_color}" "${tmp_gch_type_no}")" 
            return 1
        fi
        
        # step 2: selet gch_publish_type: release or snapshot
        while TRUE
        do
            tmp_step_hint_str="GCH_Type:$(getArrayItemValue "gch_type" "${tmp_gch_type_no}")"
            tmp_publish_type=$(getGCHPublishType "${tmp_step_hint_str}")

            if [ "$?" -gt "0" ]
            then
                printf "%b\n" "$(getColorStr "${bold_red_color}" "${tmp_publish_type}")" 
                # back up previous menu
                break
            fi

            tmp_step_hint_str="${tmp_step_hint_str};Publish_Type:${tmp_publish_type}"
            tmp_version=$(getGCHVersion "${tmp_publish_type}" "${tmp_step_hint_str}")

            if [ "$?" -gt "0" ]
            then
                printf "%b\n" "$(getColorStr "${bold_red_color}" "${tmp_version}")" 
                continue
                # return 1
            fi
            
            tmp_steps_finish_flg="1"
            break
        done
        
        if [ "${tmp_steps_finish_flg}" = "1" ]
        then
            break
        fi
    done
    


    case "${tmp_gch_type_no}" in
        0)  getGCHLibSampleProject "${tmp_publish_type}" "${tmp_version}"
            return 0
            ;;
        1)  getGCHIPCSampleProject "${tmp_publish_type}" "${tmp_version}"
            return 0
            ;;
        2)  getGCHBothLibIPCSampleProject "${tmp_publish_type}" "${tmp_version}"
            return 0
            ;;
        *) printf "Invalid GCH type No.\n"
            return 1
            ;;
    esac
}


export -f mvnDepJarList
export -f genStrFromPattern
export -f checkISNum
export -f getArrayItemValue
export -f getSelectOptionValue
export -f downloadGCHSampleProject
export -f clearGCHDownloadDir
export -f macroGetGCHSampleProject
export -f getGCHLibSampleProject
export -f getGCHIPCSampleProject
export -f getGCHBothLibIPCSampleProject
export -f getGCHComponentVersionList
export -f getGCHVersion
export -f getGCHPublishType
export -f getGCHSampleProject


