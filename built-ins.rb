module BuiltIn
    require_relative "config"

    def self.cd(args)
        if args.length > 1
            begin
                Dir.chdir args[1] || Dir.home
            rescue Errno::ENOENT
                puts "No such directory: #{args[1]}"
            end
        else
            puts "Usage: cd <directory>"
        end
    end

    def self.path(args)
        if args.length > 2
            args.slice(1, args.length).each { |arg|
                ShellConfig.path + ":" + arg + ":"
            }
        end

        STDIN.cooked do
            puts ShellConfig.path
        end
    end
end
