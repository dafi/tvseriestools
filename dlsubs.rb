#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'uri'
require 'json'
require 'fileutils'
require_relative './pretty_format_movie_name'
require_relative './common'

options = Common.parse_command_line('subs.json')
options.excludeExts = ['.mp4', '.avi', '.mkv']

# Used to download missing subtitles from specified url list
class SubsDownloader
    def initialize(options)
        @options = options
        FileUtils.mkdir_p @options.outputPath unless File.exist?(@options.outputPath)
    end

    def download
        @tvseries_list = Common.get_tvseries_from_folders(
            @options.seriesFolders,
            @options.excludedFolders)
        @options.feeds.each { |s| send(s['titleParser'], s['feedUrl']) }
    end

    def subspedia_downloader(url, title)
        movie_name = subspedia_movie_from_title(title)
        return if movie_name.nil? || episode_exist?(movie_name)

        html_page = open(url).read
        subs_url = 'http://www.subspedia.tv/' + html_page.match(/onClick=.downloadSub\('(.*?)'/)[1]
        download_missing_tv_series_subs(subs_url, movie_name)
    end

    def subspedia(url)
        Nokogiri::XML(open(url)).xpath('//channel/item').each do |item|
            # expand the & character to the string 'and'
            title = item.xpath('title').text.sub(/&/, 'and')
            url = item.xpath('link').text
            subspedia_downloader(url, title)
        end
    end

    def subspedia_movie_from_title(title)
        m = title.tr(' ', '.').match(/(.*?)\((\d+)x(\d+)\)/)
        file_name = m[1]
        season = format('%02d', m[2])
        episode = format('%02d', m[3])

        file_name = file_name + 'S' + season + 'E' + episode + '.srt'
        PrettyFormatMovieName.parse(file_name)
    end

    def subsfactory(url)
        Nokogiri::XML(open(url)).xpath('//channel/item').each do |item|
            movie_name = subsfactory_movie_from_title(item.xpath('title').text)
            next if movie_name.nil? || episode_exist?(movie_name)

            url = item.xpath('content:encoded').text.match(/href="(.*?download.*?)"/)[1]
            download_missing_tv_series_subs(url, movie_name, 'zip')
        end
    end

    def subsfactory_movie_from_title(title)
        # to allow a correct parsing replace some chars and append a fake extension
        title.gsub!("\xD7".force_encoding('ISO-8859-1').encode('UTF-8'), 'x')
        title.gsub!(/[- ]/, '.')
        title.gsub!(/&/, 'and')
        title += '.ext'

        PrettyFormatMovieName.parse(title)
    end

    def episode_exist?(movie)
        !@options.searchPaths.index do |search_path|
            path = search_path.gsub('%1', movie.showName)
            Common.episode_exist?(path, movie, @options.excludeExts)
        end.nil?
    end

    def download_missing_tv_series_subs(url, movie_name, default_ext = nil)
        show_name = movie_name.showName.downcase
        @tvseries_list.each do |tv_serie|
            next unless tv_serie.downcase == show_name
            download_subs(url, movie_name, default_ext)
        end
    end

    def download_subs(url, movie_name, default_ext = nil)
        movie_name_copy = movie_name.clone
        # the downloaded file could be .zip or .srt so use its own extension
        movie_name_copy.ext = get_url_extension(url, default_ext)
        file_name = movie_name_copy.format

        puts "Downloading #{file_name}"
        open(File.join(@options.outputPath, file_name), 'wb') do |file|
            file << open(url).read
        end
    end

    def get_url_extension(url, default_ext)
        m = URI(url).path.match(/^.*\.(.*)$/)
        m ? m[1] : default_ext.nil? ? '' : default_ext
    end
end

SubsDownloader.new(options).download
