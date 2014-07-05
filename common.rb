require 'zip'
require "./prettyFormatMovieName"

class Common
    def self.episode_exist?(path, newTitle, excludeExts)
        # episode_exist is false by default so we handle the case
        # there isn't any episode for passed title
        episode_exist = false
        # iterate all files to be sure the newest is checked
        Dir[File.join(path, "*")].each { |f|
            next if excludeExts.include?(File.extname(f))
            parsed = PrettyFormatMovieFilename.parse(File.basename(f))

            # puts "#{newTitle.showName} -- #{episode_exist}"
            # # compare showName removing all not alphanumeric characters
            if parsed && newTitle.showName.gsub(/[^a-zA-Z0-9]/i, '') == parsed.showName.gsub(/[^a-zA-Z0-9]/i, '')
                next if newTitle.season < parsed.season
                episode_exist = newTitle.episode <= parsed.episode
             end
        }

        return episode_exist
    end

    def self.renamePrettified(path, oldName)
        newName = PrettyFormatMovieFilename.format(oldName)

        if newName
            File.rename(File.join(path, oldName), File.join(path, newName))
        else
            puts "Unable to rename file #{oldName}"
        end
    end

    def self.getOutputPath(scriptDir, config)
        if config["outputPath"] == nil
            return File.join(scriptDir, 'tmptest')
        end

        # check if absolute path
        if config["outputPath"].start_with?(File::SEPARATOR)
            return config["outputPath"]
        end

        return File.join(scriptDir, config["outputPath"])
    end

    def self.unzipAndPrettify(zipPath, destPath, deleteZip)
        on_exists = Zip.on_exists_proc
        Zip.on_exists_proc = true
        Zip::File.open(zipPath) do |zip_file|
            zip_file.each do |entry|
                entry.extract(File.join(destPath, entry.name))
                self.renamePrettified(destPath, entry.name)
            end
        end
        Zip.on_exists_proc = on_exists
        
        File.delete(zipPath) if deleteZip
    end
end