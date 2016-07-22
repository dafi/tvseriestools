#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'uri'
require 'json'
require 'fileutils'
require_relative './prettyFormatMovieName'
require_relative './common'

options = Common.parse_command_line('subs.json')
options.excludeExts = ['.mp4', '.avi', '.mkv']

class SubsDownloader
    def initialize(options)
        @options = options
        FileUtils::mkdir_p @options.outputPath if !File.exist?(@options.outputPath)
        @subsList = [
            {'feedUrl' => 'http://www.subspedia.tv/feed', 'titleParser' => 'subspedia'},
            {'feedUrl' =>'http://www.subsfactory.it/categorie/sottotitoli/feed', 'titleParser' => 'subsfactory'}
        ]
    end

    def download
        @tvseries_list = Common.get_tvseries_from_folders(@options.seriesFolders, @options.excludedFolders)
        @subsList.each do |s|
            send(s['titleParser'], s['feedUrl'])
        end
    end

    def subspedia_downloader(url, title)
        m = title.gsub!(/ /, '.').match(/(.*?)\((\d+)x(\d+)\)/)
        fileName = m[1]
        season = m[2]
        episode = m[3]
        if (season.length == 1)
            season = '0' + season
        end
        if (episode.length == 1)
            episode = '0' + episode
        end
        fileName = fileName + 'S' + season + 'E' + episode + '.srt'
        movieName = PrettyFormatMovieFilename.parse(fileName)

        return unless movieName
        showName = movieName.showName.downcase()

        return if @options.searchPaths.index { |searchPath|
            path = searchPath.gsub('%1', movieName.showName)
            Common.episode_exist?(path, movieName, @options.excludeExts)
        }
        @tvseries_list.each do |tvSerie|
            if tvSerie.downcase() == showName
                # badPrefix = /http:\/\/www.weebly.com.*http/
                # fixedUrl = url.gsub(badPrefix, 'http')
                # if url != fixedUrl
                #     puts "Fixed invalid url #{url}to #{fixedUrl}"
                #     url = fixedUrl
                # end
                puts "Downloading #{movieName.format}"
                html_page = open(url).read
                subs_url = 'http://www.subspedia.tv/' + html_page.match(/onClick=.downloadSub\('(.*?)'/)[1]
                fullDestPath = File.join(@options.outputPath, movieName.format)
                open(fullDestPath, 'wb') do |file|
                    file << open(subs_url).read
                end
            end
        end
    end

    def subspedia(url)
        Nokogiri::XML(open(url)).xpath('//channel/item').each do |item|
            # expand the & character to the string 'and'
            title = item.xpath('title').text.sub(/&/, 'and')
            url = item.xpath('link').text
            subspedia_downloader(url, title)
        end
    end

    def subsfactory(url)
        Nokogiri::XML(open(url)).xpath('//channel/item').each do |item|
            title = item.xpath('title').text
            # to allow a correct parsing replace some chars and append a fake extension
            title.gsub!("\xD7".force_encoding('ISO-8859-1').encode('UTF-8'), 'x')
            title.gsub!(/[- ]/, '.')
            title.gsub!(/&/, 'and')
            title = title + '.ext'

            movieName = PrettyFormatMovieFilename.parse(title)
            next unless movieName
            showName = movieName.showName.downcase()

            next if @options.searchPaths.index { |searchPath|
                path = searchPath.gsub('%1', movieName.showName)
                Common.episode_exist?(path, movieName, @options.excludeExts)
            }

            url = item.xpath('content:encoded').text.match(/href="(.*?download.*?)"/)[1]

            @tvseries_list.each do |tvSerie|
                if tvSerie.downcase() == showName
                    puts "Downloading #{title}"
                    fullDestPath = File.join(@options.outputPath, movieName.format + '.zip')
                    open(fullDestPath, 'wb') do |file|
                        file << open(url).read
                    end
                    # Common.unzipAndPrettify(fullDestPath, @options.outputPath, true)
                end
            end
        end
    end

end

SubsDownloader.new(options).download
