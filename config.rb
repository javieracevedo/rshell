module ShellConfig
    RGB_COLOR_MAP = {
        cyan: "139;233;253",
        green: "80;250;123",
        red: "255;85;85"
    }.freeze

    @path = []
    @prompt_color = "white"
    @qotd_list = []

    MODE = "interactive" if ARGV.length == 0 
    MODE = "batch" if ARGV.length == 1

    def self.path
        @path
    end

    def self.prompt_color
        @prompt_color
    end

    def self.qotd_list
        @qotd_list
    end

    def self.apply_config_file()
        File.open("rshell.cfg", "r") do |f|
            f.each_line do |line|
                splitted_line = line.split("=")
                if (splitted_line.length == 2)
                    lhs = splitted_line[0]
                    rhs = splitted_line[1]

                    if lhs == "prompt_color"
                        @prompt_color = rhs
                    elsif lhs == "path"
                        line.split("=")[1].split(":").each { |entry|
                            @path << rhs
                        }
                    elsif lhs == "qotd_list"
                        rhs.split(",").each { |entry|
                            @qotd_list << entry
                        }
                    end
                end
            end
        end
    end
end