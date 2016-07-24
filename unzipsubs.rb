#!/usr/bin/env ruby
# Extract from .zip the subtitles .srt files
# then prettify the .srt files and delete the original .zip
# Only zip file names in tvseries format are unzipped
# If the zip file contains more than one srt files they are all unzipped on a directory

require 'json'
require_relative './prettyFormatMovieName'
require_relative './common'

options = Common.parse_command_line('subs.json')

def create_unzipped_directory(zip_path, dest_path, zip_entries)
    unzipped_dirname = File.basename(zip_path).gsub(/\.?\.zip$/, '.unzipped')
    dest_path = File.join(dest_path, unzipped_dirname)
    FileUtils.mkdir_p dest_path unless File.exist?(dest_path)
    zip_entries.each { |entry| entry.extract(File.join(dest_path, entry.name)) }
end

def unzip_and_prettify(zip_path, dest_path, delete_zip)
    on_exists = Zip.on_exists_proc
    Zip.on_exists_proc = true

    Zip::File.open(zip_path) do |zip_file|
        zip_entries = zip_file.glob('*.srt')

        if zip_entries.count == 1
            Common.renamePrettified(dest_path, zip_entries.first.name)
        elsif zip_entries.count > 1
            create_unzipped_directory(zip_path, dest_path, zip_entries)
        end
    end
    Zip.on_exists_proc = on_exists

    File.delete(zip_path) if delete_zip
end

# Test to see if the file_name is already prettified
def prettified?(file_name)
    parsed = PrettyFormatMovieFilename.parse(file_name)

    return parsed.nil? && parsed.format == file_name
end

def prettify_file(dest_path, file_name)
    Common.renamePrettified(dest_path, file_name) unless prettified?(file_name)
end

def prettify_archive(zip_path, dest_path, delete_zip)
    # unzip only filename in tv series format
    parsed = PrettyFormatMovieFilename.parse(File.basename(zip_path))

    unzip_and_prettify(zip_path, dest_path, delete_zip) if parsed
end

def prettify_directory(src_path, dest_path, delete_zip)
    Dir.foreach(src_path).each do |f|
        extname = File.extname(f)

        case extname
        when '.zip'
            zip_path = File.join(src_path, f)
            prettify_archive(zip_path, dest_path, delete_zip)
        when '.srt'
            prettify_file(dest_path, f)
        end
    end
end

prettify_directory(options.outputPath, options.outputPath, true)
