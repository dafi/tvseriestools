# This class split a movie name into its components
# it's possible to format the name into an uniform manner
class PrettyFormatMovieName
    attr_accessor :showName
    attr_accessor :season
    attr_accessor :episode
    attr_accessor :extraText
    attr_accessor :ext
    attr_accessor :year

    def self.parse(file_name)
        file = file_name.gsub(/\s+/, '.')

        year = extract_year(file)

        # handle file name of type sDDeDD or DxXX where D = digit
        file.match(/(^.*?)[^a-z0-9]s?([0-9]{1,2})\.?[e|x]?([0-9]{2})(\.?.*)(\..{3})/i) do |m|
            p = PrettyFormatMovieName.new
            p.showName = normalize_show_name(m[1])
            p.season = m[2].to_i
            p.episode = m[3].to_i
            p.extraText = m[4].downcase
            p.ext = m[5].gsub(/^\.+/, '').downcase
            p.year = year
            return p
        end

        nil
    end

    def self.extract_year(str)
        str.match(/.([0-9]{4})./) do |m|
            str.gsub!(/.[0-9]{4}./, '.')
            return m[1]
        end
        ''
    end

    def self.normalize_show_name(str)
        # replace '-' and _' with '.'
        # and ensure '.' isn't repeated (eg '...' must be '.')
        dot_case(str).gsub(/[^a-z0-9]+$/i, '').gsub(/[-_.]+/, '.')
    end

    def self.dot_case(str)
        str
            .gsub(/(.)([A-Z][a-z]+)/, '\1.\2')
            .gsub(/([a-z0-9])([A-Z])/, '\1.\2')
            .downcase
    end

    def self.from_map(map)
        p = PrettyFormatMovieName.new

        p.showName = map['showName']
        p.season = map['season']
        p.episode = map['episode']
        p.extraText = map['extraText']
        p.ext = map['ext']
        p.year = map['year']

        p
    end

    def self.format(file_name, full = false)
        movie = PrettyFormatMovieName.parse(file_name)
        movie ? movie.format(full) : nil
    end

    def format(full = false)
        s = sprintf('%s.s%02de%02d', @showName, @season, @episode)
        s << '.' + @extraText unless !full || extraText.nil? || @extraText.empty?
        s << '.' + @ext unless @ext.nil? || @ext.empty?
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
        "showName: #{@showName}" \
        " season: #{@season}" \
        " episode: #{@episode}" \
        " extraText: #{@extraText}" \
        " ext: #{@ext}" \
        " year: #{@year}"
    end

    def same_episode?(other)
        @showName == other.showName &&
            @season == other.season &&
            @episode == other.episode
    end

    def older_episode?(other)
        # compare showName removing all not alphanumeric characters
        if showName.gsub(/[^a-zA-Z0-9]/i, '') == other.showName.gsub(/[^a-zA-Z0-9]/i, '')
            return season < other.season || episode <= other.episode
        end
        false
    end
end
