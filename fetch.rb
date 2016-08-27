#!/usr/bin/env ruby
require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'
require 'uri'
require 'fileutils'
require_relative './pretty_format_movie_name'
require_relative './common'
require_relative './torrent_utils'

options = Common.parse_command_line('feeds.json')

# files ending with these extensions will be not considered movies
# and will not be used to check if movies must be downloaded
options.excludeExts = ['.zip', '.srt']

# Download .torrent files for missing episodes
class TorrentDownloader
    def initialize(options)
        @options = options
        @torrents_path = options.outputPath

        @blank_line = ' ' * `/usr/bin/env tput cols`.to_i
    end

    def fetch
        FileUtils.mkdir_p @torrents_path unless File.exist?(@torrents_path)

        delete_orphan_torrents

        tvseries_list = Common.get_tvseries_from_folders(@options.seriesFolders, @options.excludedFolders)
        episodes = []
        @options.aggregators.each do |template_url|
            find_missing_episodes(tvseries_list, template_url, episodes)
        end
        download_all(episodes)
    end

    def delete_orphan_torrents
        Dir.glob(File.join(@torrents_path, '*.torrent')).each { |f| File.delete(f) }
    end

    def find_missing_episodes(tvseries_list, template_url, episodes)
        tvseries_list.each_with_index do |name, index|
            print "#{@blank_line}\r"
            print "#{index + 1}/#{tvseries_list.length} #{name}\r"
            episodes.concat(get_url(get_aggregator_url(template_url, name), name))
        end
        puts
    end

    def get_aggregator_url(aggregator_template_url, name)
        aggregator_template_url.gsub('%1', name)
    end

    def get_url(url, name)
        episodes = []

        Nokogiri::XML(open(url, allow_redirections: :safe)).xpath('//item').each do |item|
            link = link_from_rss_node(item)
            title = item.xpath('title').text

            next unless link
            # skip 720p and 1080p files
            next if title =~ /\b(480p|720p|1080p)\b/

            new_ep = find_newer_episode(title, link, name)
            next if !new_ep || contain_episode?(episodes, new_ep['movie'])
            episodes.push(new_ep)
        end
        episodes
    end

    def link_from_rss_node(item)
        # the direct link to the .torrent file could be inside the enclosure tag
        enclosure = item.xpath('enclosure')
        return enclosure.xpath('@url').text unless enclosure.empty?
        item.xpath('link').text
    end

    def find_newer_episode(title, link, name)
        movie = PrettyFormatMovieName.parse(title)
        if movie && movie.showName == name
            index = @options.searchPaths.index do |search_path|
                path = search_path.gsub('%1', movie.showName)
                Common.episode_exist?(path, movie, @options.excludeExts)
            end
            return { 'movie' => movie, 'link' => link } if index.nil?
        end
    end

    # The feed page can contain more links for the same episode
    # so check if the episodes list already contains it
    def contain_episode?(episodes, new_episode)
        !episodes.index do |ep|
            ep['movie'].same_episode?(new_episode)
        end.nil?
    end

    def download_all(episodes)
        episodes.each do |title|
            pretty_name = title['movie'].format
            print "Downloading #{pretty_name}..."
            download_torrent(title['link'], pretty_name)
            puts ' done'
        end
    end

    def download_torrent(url, label)
        torrent_url = TorrentUtils.instance.get_torrent_url_from_feed(url)
        full_dest_path = File.join(@torrents_path, label + '.torrent')
        open(full_dest_path, 'wb') do |file|
            file << open(torrent_url, allow_redirections: :safe).read
        end
    end
end

TorrentUtils.instance.load_search_engines(options.searchEngineConfigPath)
TorrentUtils.instance.setup_feeds
TorrentDownloader.new(options).fetch
