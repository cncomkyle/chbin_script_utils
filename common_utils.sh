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
function dgchsp()
{
    local ver_str="$1"
    
    if [  -z "${ver_str}"  ]
    then
        printf "Please input the right version number !\n"
        return 1
    fi

    local maven_repo_url_pattern="http://engci-maven.cisco.com/artifactory/cstg-gch-java-group/com/gch/callhome/{project_name}/{version_info}"

    proj_nms[0]="pd_demo_with_gch_ipc"
    proj_nms[1]="gch_process_with_ipc"
    proj_nms[2]="pd_demo_with_gch_lib"

    for tmp_proj_nm in "${proj_nms[@]}"
    do
        local zip_file_nm="${tmp_proj_nm}-${ver_str}-project.zip"
        local download_url=$(genStrFromPattern "${maven_repo_url_pattern}/${zip_file_nm}" "${tmp_proj_nm}" "${ver_str}")
        printf "Begin download %s\n" "${download_url}"
        wget "${download_url}" > /dev/null 2>&1

        if [ "$?" -gt "0" ] 
        then
            printf "Fail to download from %s\n" "${download_url}"
        fi

        if [ -e "${zip_file_nm}" ]
        then
            printf "Begin unzip %s\n" "${zip_file_nm}"
            unzip "${zip_file_nm}" > /dev/null 2>&1
        else
            printf "Fail to download file %s\n" "${zip_file_nm}"
            return 1
        fi
    done
}


# get the maven dependency build-classpath exact file path list
function getMvnDep()
{
    mvn dependency:build-classpath 2>&1 | sed -n -e '/\.jar/p' | sed -n -e '/http:/!p' |  awk -F ':' '{for(i=1;i<=NF;i++)print$i}'
}
