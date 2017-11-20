function getSSLCertChain()
{
    local l_site_name="$1"
    if [ -z "${l_site_name}" ]
    then
        printf "please input the SSL Site Name\n"
        return 1
    fi
    local l_rlt=$(openssl s_client -servername "${l_site_name}" -connect "${l_site_name}:443" 2>&1 < /dev/null)

    local l_chain=$(printf "%s\n" "${l_rlt}" | \
                    awk 'BEGIN{flg=0}{if($0~/---/){if(flg==1)exit;flg=1;}if(flg==1)print $0}')

    if [ -z "${l_chain}" ]
    then
        printf "%s\n" "${l_rlt}"
    else
        printf "%s\n" "${l_chain}"
    fi
}
function checkLine()
{
    local l_src_line="$1"
    local l_dst_line="$2"

    local l_check_rlt=$(printf "%s\n" "${l_src_line}" | sed -n -e '/'"${l_dst_line}"'/p')

    if [ -n "${l_check_rlt}" ]
    then
        printf "1\n"
        return 0
    else
        printf "0\n"
        return 1
    fi
}
function createSinglePem()
{
    local l_parent_folder="$1"
    local l_pem_num="$2"
    local l_pem_str="$3"

    # create the single pem folder
    local l_pem_folder="${l_parent_folder}/${l_pem_num}"
    mkdir -p "${l_pem_folder}"

    # create the pem file
    local l_pem_file_path="${l_pem_folder}/${l_pem_num}.pem"
    printf "%s\n" "${l_pem_str}" > "${l_pem_file_path}"

    # get the pem detail content
    local l_pem_content="${l_pem_folder}/${l_pem_num}_pem_content.txt"
    keytool -printcert -file "${l_pem_file_path}" > "${l_pem_content}"

    # get the pem owner and issuer info
    local l_tmp_result=$(cat "${l_pem_content}" | sed -n -e '{/Owner:/p;/Issuer:/p;}' | awk '{printf"##%s",$0}END{printf"\n"}')

    printf "[%s].%s\n" "${l_pem_num}" "${l_tmp_result}"
}

function getPemStoreFolderNm()
{
    local l_pem_file_name="$1"
    printf "%s_split_folder\n" "${l_pem_file_name}" | sed -n -e 's/\./_/g;p;'
}

function parsePemFile()
{
    local l_target_pem_path="$1"

    # check the validation of the pem file path
    if [ -z "${l_target_pem_path}" ]
    then
        printf "Please input the parse PEM file path!\n"
        return 1
    fi

    if [ ! -e "${l_target_pem_path}" ]
    then
        printf "%s is invalid file path!\n" "${l_target_pem_path}"
        return 1
    fi

    local l_pem_file_name=$(basename "${l_target_pem_path}")
    # create the store folder
    # local l_pems_folder=$(printf "%s_split_folder\n" "${l_pem_file_name}" | sed -n -e 's/\./_/g;p;')
    local l_pems_folder=$(getPemStoreFolderNm "${l_pem_file_name}")

    if [ -d "${l_pems_folder}" ]
    then
        rm -fr "${l_pems_folder}"
    fi

    mkdir -p "${l_pems_folder}"

    if [ ! -d "${l_pems_folder}" ]
    then
        printf "Cannot create the %s under current folder\n" "${l_pems_folder}"
        return 1
    fi

    local l_summary_file="${l_pems_folder}/summary.txt"
    local l_pem_cnt=0
    local l_tmp_pem_str=""
    # split the pem file
    local l_begin_flg="0"
    local l_end_flg="0"
    local l_begin_line="-----BEGIN CERTIFICATE-----"
    local l_end_line="-----END CERTIFICATE-----"
    local l_tmp_summary_str=""
    while read -r tmpLine
    do
        # printf "%s\n" "${tmpLine}"
        # check begin line : -----BEGIN CERTIFICATE-----
        if [ "${l_begin_flg}" = "0" ]
        then
            l_begin_flg=$(checkLine "${tmpLine}" "${l_begin_line}")
            if [ "${l_begin_flg}" = "1" ]
            then
                l_end_flg="0"
            fi
        fi
        
        if [ "${l_begin_flg}" = "1" ]
        then
            l_tmp_pem_str=$(printf "%s\n%s" "${l_tmp_pem_str}" "${tmpLine}")
            # check end line : -----END CERTIFICATE-----
            l_end_flg=$(checkLine "${tmpLine}" "${l_end_line}")
            if [ "${l_end_flg}" = "1"  ]
            then
                l_begin_flg="0"
                let l_pem_cnt=$(($l_pem_cnt+1))
                l_tmp_summary_str=$(createSinglePem "${l_pems_folder}" "${l_pem_cnt}" "${l_tmp_pem_str}")
                printf "%s\n" "${l_tmp_summary_str}" >> "${l_summary_file}"
                # printf "%s [%d]\n" "${l_tmp_pem_str}" "${l_pem_cnt}"
                l_tmp_pem_str=""
            fi
        fi

    done < "${l_target_pem_path}"
}
function curlHttpsGetTest()
{
    local l_check_https_url="$1"
    local l_check_pem_path="$2"

    curl -s --cacert "${l_check_pem_path}" -G "${l_check_https_url}" 2>&1 > /dev/null
    if [ "$?" = "0" ]
    then
        printf "1\n"
    else
        printf "0\n"
    fi
}

function sslCertHttpsTest()
{
    local l_check_https_url="$1"
    local l_check_pem_name="$2"

    if [ -z "${l_check_https_url}" ]
    then
        printf "Please input the https test URL!!!\n"
        return 1
    fi

    if [ -z "${l_check_pem_name}" ]
    then
        printf "Please input the test pem file name!!!\n"
        return 1
    fi

    local l_pems_folder=$(getPemStoreFolderNm "${l_check_pem_name}")
    local l_pem_summary_file="${l_pems_folder}/summary.txt"
    local l_test_pem_path=""
    local l_pem_num=""
    local l_curl_test_rlt=""
    while read -r l_tmp_line
    do
        l_pem_num=$(printf "%s\n" "${l_tmp_line}" | sed -n -e 's/\[\([0-9][0-9]*\)\].*/\1/g;p;')
        l_test_pem_path="${l_pems_folder}/${l_pem_num}/${l_pem_num}.pem"
        l_curl_test_rlt=$(curlHttpsGetTest "${l_check_https_url}" "${l_test_pem_path}")
        if [ "${l_curl_test_rlt}" = "1" ]
        then
            printf "%s\n" "${l_tmp_line}"
        fi
    done < "${l_pem_summary_file}"
    
}
