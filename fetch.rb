require 'open-uri'
require 'nokogiri'
require "uri"
require "json"
require 'fileutils'
require "./prettyFormatMovieName"
require "./common"
require "./TorrentUtils"

scriptDir = File.dirname File.expand_path $0
$config = JSON.parse(open(File.join(scriptDir, "feeds.json")).read)
$feeds = $config["feeds"]
$searchPaths = $config["searchPaths"]
$outputPath = Common.getOutputPath(scriptDir, $config)

$torrentsOutputPath = File.join($outputPath, 'torrents')
$reportOutputPath = File.join($outputPath, 'listmovies.html')

# files ending with these extensions will be not considered movies
# and will not be used to check if movies must be downloaded
$excludeExts = ['.zip', '.srt'];
$blankLine = " " * 60

def get_url(url, titles_array)
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
        add_title(titles_array, obj)
    end
end

def add_title(titles_array, title)
    titles_array.push(title)
    if title["movie"]
        print "#{$blankLine}\r"
        print "#{titles_array.length}/#{$feeds.length} #{title["movie"].showName}\r"
    end

    if titles_array.length == $feeds.length
        titles_array.keep_if { |el|
            !el["movie"].nil?
        }
        titles_array.sort! { |a,b|
            a["movie"].showName <=> b["movie"].showName
        }
        print "#{$blankLine}\r"
        show_new_titles(titles_array)
    end
end

def show_new_titles(titles_array)
    itemsNews = []
    links = []

    titles_array.each do |title|
        next if $searchPaths.index { |searchPath|
            path = searchPath.gsub('%1', title["movie"].showName)
            Common.episode_exist?(path, title["movie"], $excludeExts)
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
        fullDestPath = File.join($torrentsOutputPath, link["label"] + '.torrent');
        open(fullDestPath, 'wb') do |file|
            file << open(torrentUrl).read
        end
    end

    html = html.gsub('%1', htmlBody)
    File.write($reportOutputPath, html)
end

def fetch_torrents
    titles = []
    FileUtils::mkdir_p $outputPath if !File.exist?($outputPath)
    FileUtils::mkdir_p $torrentsOutputPath if !File.exist?($torrentsOutputPath)

    $feeds.each do |url|
        get_url(url, titles)
    end
end

fetch_torrents


