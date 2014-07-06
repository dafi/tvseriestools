class TorrentUtils
    TorrentInfo = [
    {
    "re" => /href="http:\/\/www.torlock.com\/torrent\/([0-9]+)\/.*?"/,
    "urlPattern" => 'http://www.torlock.com/tor/$1.torrent'
    },

    {
    "re" => /http:\/\/www.newtorrents.info\/torrent\/([0-9]+)\/*/,
    "urlPattern" => 'http://www.newtorrents.info/down.php?id=$1'
    },

    {
    "re" => /href="http:\/\/h33t.com\/torrent\/([0-9]+)\/.*?"/,
    "urlPattern" => 'http://h33t.com/get/$1'
    },

    {
    "re" => /href="http:\/\/www.torrentfunk.com\/torrent\/([0-9]+)\/.*?"/,
    "urlPattern" => 'http://www.torrentfunk.com/tor/$1.torrent'
    },

    {
    "re" => /href="http:\/\/www\.bt-chat\.com\/details\.php\?id=([0-9]+).*?"/,
    "urlPattern" => 'http://www.bt-chat.com/download.php?id=$1'
    },
    ]

    def self.getTorrentUrlFromFeedUrl(feedUrl)
        html = open(feedUrl).read.gsub(/(\n|\r|\t)/, '')

        torrentUrl = feedUrl
        TorrentInfo.index do |torrent|
            m = html.match(torrent["re"])
            if m && m.length == 2
                torrentUrl = torrent["urlPattern"].gsub('$1', m[1])
                true
            end
        end

        return torrentUrl
    end
end