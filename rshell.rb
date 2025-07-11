require 'io/console'

module RShell
    require_relative "built-ins"
    require_relative "config"

    CD_CMD = "cd"
    EXIT_CMD = "exit"
    PATH_CMD = "path"

    REDIRECT_TRUNCATE_TOKEN = ">"
    REDIRECT_APPEND_TOKEN = ">>"

    def self.display_prompt()
        rgb_val = ShellConfig::RGB_COLOR_MAP[:red]
        print "\e[38;2;#{rgb_val}m@rshel #{Dir.getwd()} >> \e[0m" if ShellConfig::MODE != "batch"
    end

    def self.display_qotd()
        puts "\e[38;2;#{ShellConfig::RGB_COLOR_MAP[ShellConfig::qotd_color.to_sym]}mQuote of the Day: \n\n"
        puts "\"#{ShellConfig.qotd_list.sample(1)[0]}\"\e[0m"
        puts ""
    end

    def self.execute_command(args, output_file_path, should_truncate)
        mode = File::WRONLY | File::CREAT
        mode |= should_truncate ? File::TRUNC : File::APPEND

        out_fd = output_file_path != nil ? File.open(output_file_path, mode, 0644)  : STDOUT
        err_fd = output_file_path != nil ? out_fd : STDERR

        STDIN.cooked do
            begin
                pid = spawn(
                    { 'PATH' => ShellConfig.path },
                    *args,
                    [:out] => out_fd,
                    [:err] => err_fd
                )
                Process.wait(pid)
                status = $?.exitstatus
                puts "Exited with status #{status}" unless status == 0
                rescue Errno::ENOENT
                    puts "Command not found: #{args[0]}"
                rescue SystemCallError => e
                    puts "System error: #{e.message}"
                ensure
                    out_fd.close if output_file_path && out_fd && !out_fd.closed?
            end
        end
     end

    def self.start_interactive()
        input_buffer = ""
        prompt = "\e[38;2;#{ShellConfig::RGB_COLOR_MAP[ShellConfig::prompt_color.to_sym || :white]}m@rshel #{Dir.getwd()} >> \e[0m"
        STDIN.raw do
            print prompt

            loop do
                char = STDIN.getch

                if char == "\u007f"
                    unless input_buffer.empty?
                        input_buffer.chop!
                        print "\b \b"
                    end
                elsif char == "\r" || char == "\n"
                    print "\r\n"

                    output = process_command(input_buffer)
                    break if output == "exit"

                    input_buffer = ""
                    print "\r" + prompt
                else
                    input_buffer << char
                    print char
                end
            end
        end
    end

    def self.process_command(cmd_line)
        args = cmd_line.chomp.split

        if args.length > 0
            output_file_path = nil
            truncate_output_file = false

            redirect_operand = (args & [REDIRECT_TRUNCATE_TOKEN, REDIRECT_APPEND_TOKEN]).first
            if redirect_operand != nil
                redirect_op_index = args.index(redirect_operand)
                output_file_path = args[redirect_op_index+1]
                args = args.slice(0, redirect_op_index)
                truncate_output_file = redirect_operand == REDIRECT_TRUNCATE_TOKEN
            end


            if args[0] == EXIT_CMD
                return "exit"
            elsif args[0] == CD_CMD
                BuiltIn.cd(args)
            elsif args[0] == PATH_CMD
                BuiltIn.path(args)
            else
                execute_command(args, output_file_path, truncate_output_file)
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

