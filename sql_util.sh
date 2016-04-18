function sqlStr2JavaCode()
{
    local sql_file_path="$1"

    if [ -z "${sql_file_path}" ]  
    then
        printf "Please input the sql file path !\n"
        return 1
    fi


    if [  ! -e  "${sql_file_path}" ]
    then
        printf "Invalid sql file path : %s\n" "${sql_file_path}"
        return 1
    fi

    filename=$(basename $sql_file_path)
    java_func_name=${filename%.*}"_sql"
    bg_char="    "
    # begin
    printf "private static String %s() {\n" "${java_func_name}"
    printf "%sStringBuilder sqlBuilder = new StringBuilder();\n" "${bg_char}"
    while IFS='' read -r tmp_line
    do
        printf "%ssqlBuilder.append(\"%s\").append(\"\\\n\");\n"  "${bg_char}" "${tmp_line}"
    done < "${sql_file_path}"

    #end
    printf "%sreturn sqlBuilder.toString();\n"  "${bg_char}"
    printf "}\n"

    return 0
}

function genJavaFieldStr()
{
    local tmp_field_str="$1"

    printf "%s\n" "${tmp_field_str}" | \
    awk -F '_' '{for(i=1;i<=NF;i++){printf"%s%s",toupper(substr($i,1,1)),substr($i,2)}}END{printf"\n"}'
}

function newEntityAddValue()
{
    local sql_file_path="$1"

    local field_list=$(
        cat "${sql_file_path}" | \
        sed -n -e '/:/p' | \
        awk -F ':' '{print $NF}'
    )

    while read -r tmp_field
    do
        local tmp_get_str="get$(genJavaFieldStr "${tmp_field}")"
        printf "namedParameters.addValue(\"%s\", newEntity.%s());\n" "${tmp_field}" "${tmp_get_str}"
    done <<< "${field_list}"
}


function newEntitySetValue()
{
    local sql_file_path="$1"

    local field_list=$(
        cat "${sql_file_path}" | \
        sed -n -e '/:/p' | \
        awk -F ':' '{print $NF}'
    )

    while read -r tmp_field
    do
        local tmp_set_str="set$(genJavaFieldStr "${tmp_field}")"
        printf "newEntity.%s()\n" "${tmp_set_str}"
    done <<< "${field_list}"
}


function genResultExtractor()
{
    local sql_tbl_name="$1"

    local tbl_column_info=$(
        mysql -u root --password=root -Bse "use SmartAgentDebug;select column_name, column_type from information_schema.columns where table_name='${sql_tbl_name}'";
    )

}
