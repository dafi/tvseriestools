require 'zip'
require 'optparse'
require 'ostruct'
require 'json'
require 'tmpdir'
require_relative './pretty_format_movie_name'

# Common methods used to
# - read configurations
# - rename files
# - check file existence
class Common
    def self.episode_exist?(path, new_title, exclude_exts)
        # if path doesn't exist skip it otherwise all newTitles are considered 'new'
        return true unless File.exist?(path)

        # episode_exist is false by default so we handle the case
        # there isn't any episode for passed title
        episode_exist = false
        # iterate all files to be sure the newest is checked
        Dir[File.join(path, '*')].each do |f|
            next if exclude_exts.include?(File.extname(f))
            parsed = PrettyFormatMovieName.parse(File.basename(f))

            # puts "#{new_title.showName} -- #{episode_exist}"
            episode_exist = parsed && new_title.older_episode?(parsed)
            break if episode_exist
        end

        episode_exist
    end

    def self.rename_prettified(path, old_name)
        new_name = PrettyFormatMovieName.format(old_name)

        if new_name
            File.rename(File.join(path, old_name), File.join(path, new_name))
        else
            puts "Unable to rename file #{old_name}"
        end
    end

    def self.get_output_path(script_dir, config)
        return File.join(script_dir, 'tmptest') if config['outputPath'].nil?

        # check if absolute path
        if config['outputPath'].start_with?(File::SEPARATOR)
            return config['outputPath']
        end

        File.join(script_dir, config['outputPath'])
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

        script_dir = File.dirname File.expand_path $PROGRAM_NAME
        cmd_opts.config_file ||= File.join(script_dir, default_config_file_name)
        json_map = JSON.parse(open(cmd_opts.config_file).read)
        options = OpenStruct.new(json_map)
        # resolve path
        options.outputPath = Common.get_output_path(script_dir, json_map)
        options.aggregators = Common.expand_aggregators(options.aggregators) if options.aggregators

        options
    end
    # rubocop:enable Metrics/LineLength

    def self.get_tvseries_from_folders(series_folders, excluded_folders)
        list = []

        series_folders.each do |dir|
            Dir.foreach(dir) do |name|
                next if name == '.' || name == '..' || File.file?(name) || excluded_folders.include?(name)
                list.push(name.downcase)
            end
        end
        list
    end

    def self.expand_aggregators(aggregators)
        tmpdir = Dir.tmpdir
        # Aggregators starting with '--' are considered commented out
        aggregators
            .reject { |x| x.start_with?('--') }
            .map { |x| x.gsub('$TMP_DIR', tmpdir) }
    end
end
