require 'open-uri'
require 'nokogiri'
require "uri"
require "json"
require 'fileutils'
require_relative "./prettyFormatMovieName"
require_relative "./common"
require_relative "./TorrentUtils"

options = Common.parse_command_line('feeds.json')

# files ending with these extensions will be not considered movies
# and will not be used to check if movies must be downloaded
options.excludeExts = ['.zip', '.srt'];

class TorrentDownloader
    def initialize(options)
        @options = options
        @torrentsOutputPath = File.join(options.outputPath, 'torrents')
        @reportOutputPath = File.join(options.outputPath, 'listmovies.html')

        @blankLine = " " * `/usr/bin/env tput cols`.to_i
    end

    def fetch()
        @titles = []
        FileUtils::mkdir_p @options.outputPath if !File.exist?(@options.outputPath)
        FileUtils::mkdir_p @torrentsOutputPath if !File.exist?(@torrentsOutputPath)

        @options.feeds.each do |url|
            get_url(url)
        end
    end

    def get_url(url)
        feedXml = open(url).read

        # get just first feed item
        singleLine = feedXml.gsub(/(\n|\r|\t)/, '')
        tagItemBegin = singleLine.index('<item>')
        tagItemEnd = singleLine.index('</item>', tagItemBegin)

        singleLine = singleLine[tagItemBegin, tagItemEnd]
        title = singleLine.match(/<title>(.*?)<\/title>/)

        if title
            obj = {'movie' => PrettyFormatMovieFilename.parse(title[1])}
            link = singleLine.match(/<link>(.*?)<\/link>/)
            obj['link'] = link[1] if link
            add_title(obj)
        end
    end

    def add_title(title)
        @titles.push(title)
        if title["movie"]
            print "#{@blankLine}\r"
            print "#{@titles.length}/#{@options.feeds.length} #{title["movie"].showName}\r"
        end

        if @titles.length == @options.feeds.length

            @titles.keep_if { |el|
                !el["movie"].nil?
            }

            @titles.sort! { |a,b|
                a["movie"].showName <=> b["movie"].showName
            }
            print "#{@blankLine}\r"
            show_new_titles()
        end
    end

    def show_new_titles()
        itemsNews = []
        links = []

        @titles.each do |title|
            next if @options.searchPaths.index { |searchPath|
                path = searchPath.gsub('%1', title["movie"].showName)
                Common.episode_exist?(path, title["movie"], @options.excludeExts)
            }
            prettyName = title["movie"].format()
            puts "#{prettyName} is new"
            links.push({"url" => title["link"], "label" => prettyName})
        end
        write_html(links)
    end

    def write_html(links)
        html = "<!DOCTYPE html><html><head><title>Movies to download</title></head><body>%1</body></html>"
        htmlBody = ""

        links.each do |link|
            torrentUrl = TorrentUtils.getTorrentUrlFromFeedUrl(link["url"])
            htmlBody = htmlBody + '<a href="' + torrentUrl + '">' + link["label"] + '</a><br/>';

            # download torrent file
            fullDestPath = File.join(@torrentsOutputPath, link["label"] + '.torrent');
            open(fullDestPath, 'wb') do |file|
                file << open(torrentUrl).read
            end
        end

        html = html.gsub('%1', htmlBody)
        File.write(@reportOutputPath, html)
    end
end

TorrentDownloader.new(options).fetch
