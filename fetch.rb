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

        tvseries_list = Common.get_tvseries_from_folders(@options.seriesFolders, @options.excludedFolders)
        episodes = []
        @options.aggregators.each do |template_url|
            tvseries_list.each_with_index { |name,index|
                print "#{@blankLine}\r"
                print "#{index + 1}/#{tvseries_list.length} #{name}\r"
                episodes.concat(get_url(get_aggregator_url(template_url, name), name))
            }
        end
        download_all(episodes)
    end

    def get_aggregator_url(aggregator_template_url, name)
        return aggregator_template_url.gsub('%1', name)
    end

    def get_url(url, name)
        # force https usage
        url.gsub!(/^http/, "https")
        episodes = []

        Nokogiri::XML(open(url)).xpath("//item").each do |item|
            title = item.xpath("title").text
            link = item.xpath("link").text.gsub(/^http/, "https")

            # skip 720p and 1080p files
            next if title =~ /\b(480p|720p|1080p)\b/ 
            next if !link

            new_ep = find_newer_episode(title, link, name)
            next if !new_ep
            # skip identical episodes
            index = episodes.index { |ep|
                ep['movie'].same_episode?(new_ep['movie'])
            }
            episodes.push(new_ep) if index.nil?
        end
        return episodes
    end

    def find_newer_episode(title, link, name)
        movie = PrettyFormatMovieFilename.parse(title)
        if movie && movie.showName == name
            index = @options.searchPaths.index { |searchPath|
                path = searchPath.gsub('%1', movie.showName)
                Common.episode_exist?(path, movie, @options.excludeExts)
            }
            return {'movie' => movie, 'link' => link} if index.nil?
        end
    end

    def download_all(episodes)
        episodes.each do |title|
            prettyName = title["movie"].format()
            print "Downloading #{prettyName}..."
            download_torrent(title["link"], prettyName)
            puts " done"
        end
        puts
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
