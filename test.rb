#!/usr/bin/env ruby
require './pretty_format_movie_name'
require 'json'

def run_test_suite
    JSON.parse(open('./testSuite.json').read).each do |test|
        expected = PrettyFormatMovieName.from_map(test['expectedResult'])
        result = PrettyFormatMovieName.parse(test['inputValue'])
        next if expected == result
        puts 'Test failed'
        puts "expected #{expected}"
        puts "found    #{result}"
    end
end

run_test_suite
