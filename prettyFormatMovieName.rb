class PrettyFormatMovieFilename
    attr_accessor :showName
    attr_accessor :season
    attr_accessor :episode
    attr_accessor :extraText
    attr_accessor :ext
    attr_accessor :year

    def self.parse(fileName)
        file = fileName.downcase.gsub(/\s+/, '.')

        # remove year if present
        p = nil
        year = ""
        file.match(/.([0-9]{4})./) { |m|
            if m.length == 2
                year = m[1]
                file.gsub!(/.[0-9]{4}./, '.')
            end
        }

        # handle file name of type sDDeDD or DxXX where D = digit
        file.match(/(^.*?)\.s?([0-9]{1,2})\.?[e|x]?([0-9]{2})(.*?)\.?.*(\..{3})/i) { |m|
            if m.length == 6
                p = PrettyFormatMovieFilename.new
                # replace '_' with '.' and ensure '.' isn't repeated (eg '...' must be '.')
                p.showName = m[1].gsub(/[^a-z0-9]+$/, '').gsub(/_/, '.').gsub(/\.+/, '.')
                p.season = m[2].to_i
                p.episode = m[3].to_i
                p.extraText = m[4]
                p.ext = m[5].gsub(/^\.+/, '')
                p.year = year
            end
        }

        return p
    end

    def self.from_map(map)
        p = PrettyFormatMovieFilename.new

        p.showName = map['showName']
        p.season = map['season']
        p.episode = map['episode']
        p.extraText = map['extraText']
        p.ext = map['ext']
        p.year = map['year']

        return p
    end

    def self.format(fileName)
        movie = PrettyFormatMovieFilename.parse(fileName)
        if movie
            return movie.format
        end
        return nil
    end
    
    def format
        s = sprintf("%s.s%02de%02d", @showName, @season, @episode)
        if !@extraText.nil? && !@extraText.empty?
            s << "." + @extraText
        end
        if !@ext.nil? && !@ext.empty?
            s << "." + @ext
        end

        return s
    end

    def ==(other)
        @showName == other.showName &&
        @season == other.season && 
        @episode == other.episode && 
        @extraText == other.extraText && 
        @ext == other.ext && 
        @year == other.year
    end

    def to_s
        "showName: #{@showName}" <<
        " season: #{@season}" << 
        " episode: #{@episode}" << 
        " extraText: #{@extraText}" <<
        " ext: #{@ext}" <<
        " year: #{@year}"
    end
end
