# Extract from .zip the subtitles .srt files
# then prettify the .srt files and delete the original .zip
# Only zip file names in tvseries format are unzipped

require "json"
require_relative "./prettyFormatMovieName"
require_relative "./common"

options = Common.parse_command_line('subs.json')

def unzipAndPrettify(zipPath, destPath, deleteZip)
    on_exists = Zip.on_exists_proc
    Zip.on_exists_proc = true
    Zip::File.open(zipPath) do |zip_file|
        zip_file.each do |entry|
            if entry.name.end_with?('.srt')
                entry.extract(File.join(destPath, entry.name))
                Common.renamePrettified(destPath, entry.name)
            end
        end
    end
    Zip.on_exists_proc = on_exists
    
    File.delete(zipPath) if deleteZip
end

Dir[File.join(options.outputPath, "*.zip")].each { |f|
    parsed = PrettyFormatMovieFilename.parse(File.basename(f))

    unzipAndPrettify(f, options.outputPath, true) if parsed
}
