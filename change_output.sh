# Change the outputPath in config file subs.json
# OUT_PATH must be an absolute path
# The modified text file is written on stdout

usage() { echo "Usage: $0 [-c <config file>] [-n <new output path>]" 1>&2; exit 1; }

while getopts ":c:n:" o; do
    case "${o}" in
        c)
            CONFIG_PATH=${OPTARG}
            ;;
        n)
            OUT_PATH=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${CONFIG_PATH}" ] || [ -z "${OUT_PATH}" ]; then
    usage
fi

# example
# ./change_output.sh -c test_env/subs.json -o /home/

cat $CONFIG_PATH | json_pp | ruby -e 'ARGF.each_line { |line| puts line.gsub(/(\s+"outputPath" : ")(.*)(".*)/, "\\1'${OUT_PATH}'\\3") }'
