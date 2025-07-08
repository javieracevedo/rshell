module RShell
    require_relative "built-ins"
    require_relative "config"

    CD_CMD = "cd"
    EXIT_CMD = "exit"
    PATH_CMD = "path"

    def self.display_prompt()
        rgb_val = ShellConfig::RGB_COLOR_MAP[:red]
        print "\e[38;2;#{rgb_val}m@rshel #{Dir.getwd()} >> \e[0m" if ShellConfig::MODE != "batch"
    end

    def self.display_qotd()
        puts "\e[38;2;#{ShellConfig::RGB_COLOR_MAP[:cyan]}mQuote of the Day: \n\n"
        puts "\"#{ShellConfig.qotd_list.sample(1)[0]}\"\e[0m"
        puts ""
    end

    def self.execute_command(args)
        begin
            pid = spawn({ 'PATH' => ShellConfig.path.join(":")}, *args)
            Process.wait(pid)
            status = $?.exitstatus
            puts "Exited with status #{status}" unless status == 0
        rescue Errno::ENOENT
            puts "Command not found: #{args[0]}"
        rescue SystemCallError => e
            puts "System error: #{e.message}"
        end
    end

    def self.start_interactive()
        loop do
            display_prompt()

            args = gets.chomp.split

            next if args.length == 0

            if args[0] == EXIT_CMD
                break
            elsif args[0] == CD_CMD
                BuiltIn.cd(args)
            elsif args[0] == PATH_CMD
                BuiltIn.path(args)
            else
                execute_command(args)
            end
        end
    end

    def self.start_batch()
        loop do
            line = gets
            break if line == nil
            args = line.chomp.split

            next if args.length == 0

            if args[0] == EXIT_CMD
                break
            elsif args[0] == CD_CMD
                BuiltIn.cd(args)
            elsif args[0] == PATH_CMD
                BuiltIn.path(args)
            else
                execute_command(args)
            end
        end
    end

    def self.start()
        ShellConfig.apply_config_file()

        display_qotd()

        start_interactive() if ShellConfig::MODE == "interactive"
        start_batch() if ShellConfig::MODE == "batch"
    end
end

