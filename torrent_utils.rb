require 'singleton'
require 'json'

# This class contains helpers to find .torrent download links
# contained into html pages
# Config file format
# re - The regular expression used to locate the link to torrent service
# urlPattern - The string to build to obtain the .torrent download link, it fills $1 with the part extracted from `re`
# urlDestPage - if present then the torrent service contains the download .torrent link inside this page, it fills $1 with the part extracted from `re`
# reDestPage - The regular expression used to locate the link to torrent service contained into the `urlDestPage`
class TorrentUtils
    include Singleton

    def load_search_engines(path)
        @engine_list = JSON.parse(open(path).read)
    end

    def get_torrent_url_from_feed(feed_url)
        html = open(feed_url, allow_redirections: :safe).read.gsub(/(\n|\r|\t)/, '')

        @engine_list.each do |engine|
            torrent_id = find_torrent_id(engine, html)
            next unless torrent_id
            url = find_download_url(engine, torrent_id)
            return url if url
            # we found the matching engine
            # so in any case exit from loop
            break
        end

        feed_url
    end

    def setup_feeds
        # create the fake rss file
        fake_feed_path = File.join(Dir.tmpdir, 'torlock.xml')
        script_dir = File.dirname(File.expand_path($PROGRAM_NAME))
        torlock_to_feed(File.join(script_dir, 'feed-template.xml'), fake_feed_path)
    end

    def torlock_to_feed(feed_template_path, rss_output_path)
        base_url = 'https://torlock.unlockproject.com'
        url = "#{base_url}/television.html"
        arr = Nokogiri::HTML(open(url, allow_redirections: :safe)).css('.tv3 + a').map do |item|
            tor_id = item.attr('href').match(%r{/(\d+)/})[1]
            url = "#{base_url}/tor/#{tor_id}.torrent"
            "<item><title>#{item.text}</title><link>#{url}</link></item>"
        end

        template = open(feed_template_path).read
        template.gsub!('%items%', arr.join("\n"))
        open(rss_output_path, 'wb') { |f| f << template }
    end

    private

    # Find the torrent_id, it could be the destination page
    def find_torrent_id(engine, html)
        html.match(engine['re']) do |m|
            return m[1]
        end
    end

    def find_download_url(engine, torrent_id)
        return engine['urlPattern'].gsub('$1', torrent_id) unless engine['urlDestPage']

        url_dest_page = engine['urlDestPage'].gsub('$1', torrent_id)
        html = open(url_dest_page, allow_redirections: :safe).read.gsub(/(\n|\r|\t)/, '')
        html.match(engine['reDestPage']) do |m|
            return engine['urlPattern'].gsub('$1', m[1])
        end
    end
end
