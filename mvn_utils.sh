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
    eval "${mvn_cmd}" | \
    sed -n -e '/http:/!p' | \
    sed -n -e '/\.jar/p' | \
    awk -F ':' '{for(i=1;i<=NF;i++)print $i}'
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

function downloadGCHSampleProject()
{

    local tmp_prj_name="$1"
    local tmp_prj_ver="$2"
    local tmp_save_path="$3"

    if [ "$#" -lt 3 ]
    then
        printf "Please input {project name} {project version} {save path}\n"
        return 1
    fi


    local maven_repo_url_pattern="http://engci-maven.cisco.com/artifactory/cstg-gch-java-group/com/gch/callhome/{project_name}/{version_info}"

    local zip_file_nm="${tmp_prj_name}-${tmp_prj_ver}-project.zip"
    local download_url=$(genStrFromPattern "${maven_repo_url_pattern}/${zip_file_nm}" "${tmp_prj_name}" "${tmp_prj_ver}")
    
    printf "Begin download %s\n" "${download_url}"
    $(cd "${tmp_save_path}"; wget "${download_url}" > /dev/null 2>&1)

    
    if [ "$?" -gt "0" ] 
    then
        printf "Fail to download from %s\n" "${download_url}"
        return 1
    fi

    if [ -e "${tmp_save_path}/${zip_file_nm}" ]
    then
        printf "Begin unzip %s\n" "${zip_file_nm}"
        $(cd "${tmp_save_path}";unzip "${zip_file_nm}" > /dev/null 2>&1)
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
    local tmp_version="$1"
    local tmp_prj_array_name="$2"
    local tmp_prj_array_size="$3"
    local tmp_save_folder_name="$4"

    local tmp_save_path="$PWD/GCH_Sample_Project/$(date +%Y_%m_%d)/${tmp_version}/${tmp_save_folder_name}/"
    clearGCHDownloadDir "${tmp_save_path}"

    local tmp_index=0

    while [ "${tmp_index}" -lt "${tmp_prj_array_size}" ]
    do
        local tmp_prj_name=$(eval 'printf "%s\n" "${'$tmp_prj_array_name'['${tmp_index}']}"')
        downloadGCHSampleProject "${tmp_prj_name}" "${tmp_version}" "${tmp_save_path}"

        let tmp_index=$tmp_index+1
    done
   
}

function getGCHLibSampleProject()
{
    local tmp_version="$1"
    gch_lib_prj[0]="pd_demo_with_gch_lib"

    macroGetGCHSampleProject "${tmp_version}" "gch_lib_prj" "${#gch_lib_prj[@]}" "GCH_Lib"

    # local tmp_save_path="$PWD/GCH_Sample_Project/$(date +%Y_%m_%d)/${tmp_version}/GCH_Lib/"
    # clearGCHDownloadDir "${tmp_save_path}"

    # for tmp_prj_name in "${gch_lib_prj[@]}"
    # do
    #     downloadGCHSampleProject "${tmp_prj_name}" "${tmp_version}" "${tmp_save_path}"
    # done
}

function getGCHIPCSampleProject()
{
    local tmp_version="$1"

    local gch_ipc_prj[0]="pd_demo_with_gch_ipc"
    local gch_ipc_prj[1]="gch_process_with_ipc"

    macroGetGCHSampleProject "${tmp_version}" "gch_ipc_prj" "${#gch_ipc_prj[@]}" "GCH_IPC"

}

function getGCHBothLibIPCSampleProject()
{
    local tmp_version="$1"
    
    getGCHLibSampleProject "${tmp_version}"
    getGCHIPCSampleProject "${tmp_version}"
}

function getProjectVersionList()
{
    local tmp_prj_name="gch_core"

    local maven_metadata_url_pattern="http://engci-maven-master.cisco.com/artifactory/cstg-gch-java-group/com/gch/callhome/{project_name}/maven-metadata.xml"
    
    local tmp_maven_metadata_url=$(
        printf "%s\n" "${maven_metadata_url_pattern}" | \
        sed -n -e 's/{project_name}/'"${tmp_prj_name}"'/g;p;'
    )

    local tmp_maven_metadata_info=$(
        wget -qO - "${tmp_maven_metadata_url}" 2>&1
    )

    if [ "$?" -gt "0" ]
    then
        printf "Fail to get metadata info from %s\n!" "${tmp_maven_metadata_url}"
        exit "${LINENO}"
    fi

    if [ -z "${tmp_maven_metadata_info}" ]  
    then
        printf "Empty metadata info from %s\n" "${tmp_maven_metadata_url}"
        exit "${LINENO}"
    fi

    local tmp_version_list=$(
        printf "%s\n" "${tmp_maven_metadata_info}" | \
        sed -n -e '/<version>/p' | \
        sed -n -e 's/.*<version>\([^<>]*\)<\/version>.*/\1/g;p;' | \
        tac 
    )

    printf "%s\n" "${tmp_version_list}"
    
}


function getGCHVersion()
{
    local tmp_version_list=$(getProjectVersionList)

    if [ -z "${tmp_version_list}" ]  
    then
        printf "Cannot get GCH Version List, please check it!\n"
        return 1
    fi

    local tmp_version_no_list=$(
        printf "%s\n" "${tmp_version_list}" | \
        sed -n -e '1,5p' | \
        awk '{printf"No.[%d]    %s\n",FNR, $0}'         
    )

    while TRUE
    do
        read -e -p "$(printf "%s\n%s\n%s\n" "Please select version No. from Below version List:" "${tmp_version_no_list}" "Input No. >>>:")" tmp_version_no

        case "${tmp_version_no}" in
            1|2|3|4|5) local tmp_version=$(printf "%s\n" "${tmp_version_list}" | sed -n -e ''"${tmp_version_no}"'p')
                break
                ;;
            *) printf "Invalid Version No. \n"
               continue
               ;;
        esac
    done

    printf "%s\n" "${tmp_version}"
    
}

function getGCHSampleProject()
{
    local gch_type[0]="library"
    gch_type[1]="Process Server"
    gch_type[2]="All Above"

    local tmp_gch_type_index=0
    local tmp_gch_prj_index=0

    local tmp_gch_type_list=$(
        printf "%s\n" "${gch_type[@]}" | \
        awk '{printf"No.[%s] %s\n",NR,$0}'            
    )
    
    while TRUE
    do
        read -en1 -p "$(printf "%s\n%s\n%s\n" "Please select GCH Type from below list:" "${tmp_gch_type_list}" "Input No. >>>:" )" tmp_gch_type_no
        echo 

        case "${tmp_gch_type_no}" in
            1)  local tmp_version=$(getGCHVersion)
                if [ "$?" -gt "0" ]
                then
                    return 1
                fi
                getGCHLibSampleProject "${tmp_version}"
                return 0
                ;;
            2) local tmp_version=$(getGCHVersion)
                if [ "$?" -gt "0" ]
                then
                    return 1
                fi
                getGCHIPCSampleProject "${tmp_version}"
                return 0
                ;;
            3) local tmp_version=$(getGCHVersion)
                if [ "$?" -gt "0" ]
                then
                    return 1
                fi
                getGCHBothLibIPCSampleProject "${tmp_version}"
                return 0
                ;;
            *) printf "Invalid GCH type No.\n"
               continue
               ;;
        esac
    done
}

export -f mvnDepJarList
export -f genStrFromPattern
export -f downloadGCHSampleProject
export -f clearGCHDownloadDir
export -f macroGetGCHSampleProject
export -f getGCHLibSampleProject
export -f getGCHIPCSampleProject
export -f getGCHBothLibIPCSampleProject
export -f getProjectVersionList
export -f getGCHVersion
export -f getGCHSampleProject
