require './prettyFormatMovieName'
# require 'ostruct'
require 'json'
# require 'optparse'
# require 'ostruct'

def runTestSuite
    # openStruct needs an hash at first level so we wrap the json
    JSON.parse('{"arr": ' + open('../pretty-format-movie-filename/testSuite.json').read + '}')['arr'].each do |test|
        expected = test['expectedResult']
        result = PrettyFormatMovieFilename.parse(test['inputValue'])
        if !result || \
            result.showName != expected['showName'] || \
            result.season != expected['season'] || \
            result.episode != expected['episode'] || \
            result.extraText != expected['extraText'] || \
            result.ext != expected['ext'] || \
            result.year != expected['year']
            puts 'Test failed'
            puts 'expected ' + expected.to_s
            puts 'found ' + (result ? result.to_s : 'null')
        end
    end

end

runTestSuite

