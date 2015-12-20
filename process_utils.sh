## process  find by string match
function psfbs()
{
    local search_str="$1"
    ps -ef 2>&1 | grep "${search_str}" | sed -n -e '/grep/!p'
}
