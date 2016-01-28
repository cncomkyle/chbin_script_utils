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
