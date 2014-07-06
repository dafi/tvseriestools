require 'open-uri'
require 'nokogiri'
require "uri"
require "json"
require 'fileutils'
require "./prettyFormatMovieName"
require "./common"

scriptDir = File.dirname File.expand_path $0
config = JSON.parse(open(File.join(scriptDir, "subs.json")).read)
searchPaths = config["searchPaths"]
tvSeries = config['tvSeries']
outputPath = Common.getOutputPath(scriptDir, config)

subsList = [
        {"feedUrl" => 'http://subspedia.weebly.com/1/feed', "titleParser" => "subspedia"},
        {"feedUrl" =>'http://subsfactory.it/subtitle/rss.php?', "titleParser" => "subsfactory"}
        ]

excludeExts = ['.mp4', '.avi']

def subspedia_downloader(url, searchPaths, tvSeries, outputPath, excludeExts, title)
    fileName = File.basename(URI.parse(url).path)
    movieName = PrettyFormatMovieFilename.parse(fileName)

    return unless movieName
    showName = movieName.showName.downcase()

    return if searchPaths.index { |searchPath|
        path = searchPath.gsub('%1', movieName.showName)
        Common.episode_exist?(path, movieName, excludeExts)
    }
    tvSeries.each do |tvSerie|
        if tvSerie.downcase() == showName
            badPrefix = "http://www.weebly.com/"
            if url.start_with? badPrefix
                puts "Fixed invalid url #{url}"
                url = url[badPrefix.length, url.length]
            end
            puts "Downloading #{title}"
            fullDestPath = File.join(outputPath, fileName)
            open(fullDestPath, 'wb') do |file|
                file << open(url).read
            end
            Common.unzipAndPrettify(fullDestPath, outputPath, true)
        end
    end
end

def subspedia(url, searchPaths, tvSeries, outputPath, excludeExts)
    Nokogiri::XML(open(url)).xpath("//channel/item").each do |item|
        title = item.xpath("title").text
        item.xpath("content:encoded").text.match(/<a href='(.*zip)'/) { |m|
            url = m[1]
            subspedia_downloader(url, searchPaths, tvSeries, outputPath, excludeExts, title)
        }
    end
end

def subsfactory(url, searchPaths, tvSeries, outputPath, excludeExts)
    Nokogiri::XML(open(url)).xpath("//channel/item").each do |item|
        title = item.xpath("title").text

        movieName = PrettyFormatMovieFilename.parse(title)
        next unless movieName
        showName = movieName.showName.downcase()

        return if searchPaths.index { |searchPath|
            path = searchPath.gsub('%1', movieName.showName)
            Common.episode_exist?(path, movieName, excludeExts)
        }
        url = item.xpath("link").text
        tvSeries.each do |tvSerie|
            if tvSerie.downcase() == showName
                puts "Downloading #{title}"
                url.gsub!('action=view', 'action=downloadfile')
                fullDestPath = File.join(outputPath, "subfactory")
                open(fullDestPath, 'wb') do |file|
                    file << open(url).read
                end
                Common.unzipAndPrettify(fullDestPath, outputPath, true)
            end
        end
    end
end

FileUtils::mkdir_p outputPath if !File.exist?(outputPath)

subsList.each do |s|
    send(s['titleParser'], s['feedUrl'], searchPaths, tvSeries, outputPath, excludeExts)
end

