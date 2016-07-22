class TorrentUtils
#####
## re The regular expression used to locate the link to torrent service
## urlPattern The string to build to obtain the .torrent download link, it fills $1 with the part extracted from `re`
## urlDestPage if present then the torrent service contains the download .torrent link inside this page, it fills $1 with the part extracted from `re`
## reDestPage The regular expression used to locate the link to torrent service contained into the `urlDestPage`
#####

    TorrentInfo = [
    {
    're' => /href="http:\/\/www.torlock.com\/torrent\/([0-9]+)\/.*?"/,
    'urlPattern' => 'https://www.torlock.com/tor/$1.torrent'
    },

    {
    're' => /http:\/\/www.newtorrents.info\/torrent\/([0-9]+)\/*/,
    'urlPattern' => 'http://www.newtorrents.info/down.php?id=$1'
    },

    {
    're' => /href="http:\/\/h33t.com\/torrent\/([0-9]+)\/.*?"/,
    'urlPattern' => 'http://h33t.com/get/$1'
    },

    {
    're' => /href="http:\/\/www.torrentfunk.com\/torrent\/([0-9]+)\/.*?"/,
    'urlPattern' => 'http://www.torrentfunk.com/tor/$1.torrent'
    },

    {
    're' => /href="http:\/\/www\.bt-chat\.com\/details\.php\?id=([0-9]+).*?"/,
    'urlPattern' => 'http://www.bt-chat.com/download.php?id=$1'
    },

    {
    're' => /href="(https:\/\/rarbg.com\/torrents\/.*?.html)"/,
    'urlDestPage' => '$1',
    'reDestPage' => /Click here to download torrent.* href="(.*?.torrent)"/,
    'urlPattern' => 'https://rarbg.com$1'
    },
    ]

    def self.getTorrentUrlFromFeedUrl(feedUrl)
        html = open(feedUrl).read.gsub(/(\n|\r|\t)/, '')

        torrentUrl = feedUrl
        TorrentInfo.index do |torrent|
            m = html.match(torrent['re'])
            if m && m.length == 2
                urlDestPage = torrent['urlDestPage']
                if urlDestPage
                    urlDestPage = urlDestPage.gsub('$1', m[1])
                    htmlDestPage = open(urlDestPage).read.gsub(/(\n|\r|\t)/, '')
                    mDest = htmlDestPage.match(torrent['reDestPage'])
                    if mDest && mDest.length == 2
                        torrentUrl = torrent['urlPattern'].gsub('$1', mDest[1])
                        true
                    end
                else
                    torrentUrl = torrent['urlPattern'].gsub('$1', m[1])
                end
                true
            end
        end

        return torrentUrl
    end
end