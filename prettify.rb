#!/usr/bin/env ruby
# Prettify the file names renaming them
# The passed argument can be a single file or a directory
# If it's a directory all contained files will be prettified

require_relative 'common'

if ARGV.empty?
    puts 'Please specify a folder or file name'
else
    path = ARGV.first.to_s
    if File.file?(path)
        Common.rename_prettified(File.dirname(path), File.basename(path))
    else
        Dir.foreach(path).each do |f|
            Common.rename_prettified(path, f) unless f == '.' || f == '..'
        end
    end
end
