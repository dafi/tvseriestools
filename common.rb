require 'zip'
require 'optparse'
require 'ostruct'
require_relative './prettyFormatMovieName'

class Common
    def self.episode_exist?(path, newTitle, excludeExts)
        # if path doesn't exist skip it otherwise all newTitles are considered 'new'
        if !File.exist?(path)
            return true
        end
        # episode_exist is false by default so we handle the case
        # there isn't any episode for passed title
        episode_exist = false
        # iterate all files to be sure the newest is checked
        Dir[File.join(path, '*')].each { |f|
            next if excludeExts.include?(File.extname(f))
            parsed = PrettyFormatMovieFilename.parse(File.basename(f))

            # puts "#{newTitle.showName} -- #{episode_exist}"
            episode_exist = parsed && newTitle.older_episode?(parsed)
            break if episode_exist
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
        if config['outputPath'] == nil
            return File.join(scriptDir, 'tmptest')
        end

        # check if absolute path
        if config['outputPath'].start_with?(File::SEPARATOR)
            return config['outputPath']
        end

        return File.join(scriptDir, config['outputPath'])
    end

    # rubocop:disable Metrics/LineLength
    def self.parse_command_line(default_config_file_name)
        cmd_opts = OpenStruct.new
        cmd_opts.config_file = nil

        OptionParser.new do |opts|
            opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"

            opts.on('-c', '--config-file file', 'Use the passed config file otherwise determine the path from script directory') do |config|
                cmd_opts.config_file = config
            end

            opts.separator ''
            opts.on_tail('-h', '--help', 'This help text') do
                puts opts
                exit
            end
        end.parse!

        scriptDir = File.dirname File.expand_path $PROGRAM_NAME
        if cmd_opts.config_file.nil?
            cmd_opts.config_file = File.join(scriptDir, default_config_file_name)
        end
        json_map = JSON.parse(open(cmd_opts.config_file).read)
        options = OpenStruct.new(json_map)
        # resolve path
        options.outputPath = Common.getOutputPath(scriptDir, json_map)

        return options
    end
    # rubocop:enable Metrics/LineLength

    def self.get_tvseries_from_folders(series_folders, excluded_folders)
        list = []

        series_folders.each { |dir|
            Dir.foreach(dir) { |name|
                next if name == '.' || name == '..' || File.file?(name) || excluded_folders.include?(name)
                list.push(name.downcase())
            }
        }
        return list
    end
end
