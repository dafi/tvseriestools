require 'open-uri'
require 'nokogiri'
require "uri"
require "json"
require 'fileutils'
require_relative "./prettyFormatMovieName"
require_relative "./common"

options = Common.parse_command_line('subs.json')
options.excludeExts = ['.mp4', '.avi']

class SubsDownloader
    def initialize(options)
        @options = options
        FileUtils::mkdir_p @options.outputPath if !File.exist?(@options.outputPath)
        @subsList = [
            {"feedUrl" => 'http://subspedia.weebly.com/1/feed', "titleParser" => "subspedia"},
            {"feedUrl" =>'http://subsfactory.it/subtitle/rss.php?', "titleParser" => "subsfactory"}
        ]
    end

    def download
        @tvseries_list = Common.get_tvseries_from_folders(@options.seriesFolders, @options.excludedFolders)
        @subsList.each do |s|
            send(s['titleParser'], s['feedUrl'])
        end
    end

    def subspedia_downloader(url, title)
        fileName = File.basename(URI.parse(url).path)
        movieName = PrettyFormatMovieFilename.parse(fileName)

        return unless movieName
        showName = movieName.showName.downcase()

        return if @options.searchPaths.index { |searchPath|
            path = searchPath.gsub('%1', movieName.showName)
            Common.episode_exist?(path, movieName, @options.excludeExts)
        }
        @tvseries_list.each do |tvSerie|
            if tvSerie.downcase() == showName
                puts url
                badPrefix = /http:\/\/www.weebly.com.*http/
                fixedUrl = url.gsub(badPrefix, 'http')
                if url != fixedUrl
                    puts "Fixed invalid url #{url}"
                    url = fixedUrl
                end
                puts "Downloading #{title}"
                fullDestPath = File.join(@options.outputPath, fileName)
                open(fullDestPath, 'wb') do |file|
                    file << open(url).read
                end
#                Common.unzipAndPrettify(fullDestPath, @options.outputPath, true)
            end
        end
    end

    def subspedia(url)
        Nokogiri::XML(open(url)).xpath("//channel/item").each do |item|
            title = item.xpath("title").text
            item.xpath("content:encoded").text.match(/<a href='(.*zip)'/) { |m|
                url = m[1]
                subspedia_downloader(url, title)
            }
        end
    end

    def subsfactory(url)
        Nokogiri::XML(open(url)).xpath("//channel/item").each do |item|
            title = item.xpath("title").text

            movieName = PrettyFormatMovieFilename.parse(title)
            next unless movieName
            showName = movieName.showName.downcase()

            return if @options.searchPaths.index { |searchPath|
                path = searchPath.gsub('%1', movieName.showName)
                Common.episode_exist?(path, movieName, @options.excludeExts)
            }
            url = item.xpath("link").text
            @tvseries_list.each do |tvSerie|
                if tvSerie.downcase() == showName
                    puts "Downloading #{title}"
                    url.gsub!('action=view', 'action=downloadfile')
                    fullDestPath = File.join(@options.outputPath, "subfactory")
                    open(fullDestPath, 'wb') do |file|
                        file << open(url).read
                    end
                    Common.unzipAndPrettify(fullDestPath, @options.outputPath, true)
                end
            end
        end
    end
end

SubsDownloader.new(options).download
