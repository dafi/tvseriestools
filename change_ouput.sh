# Change the outputPath in config file subs.json
# OUT_PATH must be an absolute path
# The modified text file is written on stdout
OUT_PATH=/home/
cat test_env/subs.json | json_pp | ruby -e 'ARGF.each_line { |line| puts line.gsub(/(\s+"outputPath" : ")(.*)(".*)/, "\\1'${OUT_PATH}'\\3") }'
