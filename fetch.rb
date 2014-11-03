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

        # delete orphans torrent files
        Dir.glob(File.join(@torrentsOutputPath, '*.torrent')).each { |f| File.delete(f) }

        @tvseries_list = Common.get_tvseries_from_folders(@options.seriesFolders, @options.excludedFolders)
        @options.aggregators.each do |template_url|
            @tvseries_list.each { |name|
                get_url(get_aggregator_url(template_url, name), name)
            }
        end
    end

    def get_aggregator_url(aggregator_template_url, name)
        return aggregator_template_url.gsub('%1', name)
    end

    def get_url(url, name)
        Nokogiri::XML(open(url)).xpath("//item").each do |item|
            title = item.xpath("title").text
            link = item.xpath("link").text
            movie = PrettyFormatMovieFilename.parse(title)
            if movie && movie.showName == name
                obj = {'movie' => movie}
                obj['link'] = link if link
                add_title(obj)
                break
            end
        end
    end

    def add_title(title)
        @titles.push(title)
        if title["movie"]
            print "#{@blankLine}\r"
            print "#{@titles.length}/#{@tvseries_list.length} #{title["movie"].showName}\r"
        end

        if @titles.length == @tvseries_list.length

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

        @titles.each do |title|
            next if @options.searchPaths.index { |searchPath|
                path = searchPath.gsub('%1', title["movie"].showName)
                Common.episode_exist?(path, title["movie"], @options.excludeExts)
            }
            prettyName = title["movie"].format()
            print "Downloading #{prettyName}..."
            download_torrent(title["link"], prettyName)
            puts " done"
        end
    end

    def download_torrent(url, label)
        torrentUrl = TorrentUtils.getTorrentUrlFromFeedUrl(url)
        fullDestPath = File.join(@torrentsOutputPath, label + '.torrent');
        open(fullDestPath, 'wb') do |file|
            file << open(torrentUrl).read
        end
    end
end

TorrentDownloader.new(options).fetch
