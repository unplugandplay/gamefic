require 'thor'
require 'gamefic-sdk/build'

module Gamefic
  module Sdk
    class Shell < Thor
      autoload :Init, 'gamefic-sdk/shell/init'
      autoload :Test, 'gamefic-sdk/shell/test'

      map %w[--version -v] => :version
      map [:create, :new] => :init
      map ['scripts'] => :script

      desc "--version, -v", "Print the version"
      def version
        puts "gamefic-sdk #{Gamefic::Sdk::VERSION}"
        puts "gamefic #{Gamefic::VERSION}"
      end

      desc 'init DIRECTORY_NAME', 'Initialize a new game in DIRECTORY_NAME'
      option :quiet, type: :boolean, aliases: :q, desc: 'Suppress output'
      option :standard, type: :boolean, default: true, desc: 'Include the standard script'
      option :scripts, type: :array, aliases: [:s, :script], desc: 'Additional scripts'
      option :webskin, default: 'standard', aliases: [:w], desc: 'Skin to use for the Web platform'
      option :webdir, aliases: [:d], desc: 'HTML directory to copy. This option overrides the webskin.'
      option :title, type: :string, aliases: [:t], desc: "The game's title"
      option :author, type: :string, aliases: [:a], desc: "The game's author"
      def init(directory_name)
        Gamefic::Sdk::Shell::Init.new(
          directory: directory_name, quiet: options[:quiet], scripts: options[:scripts],
          webskin: options[:webskin], title: options[:title], author: options[:author],
          webdir: options[:webdir]
        ).run
      end

      desc 'test [DIRECTORY_NAME]', 'Play the game in DIRECTORY_NAME'
      def test(directory_name = '.')
        Gamefic::Sdk::Shell::Test.new(directory: directory_name).run
      end

      desc 'server [DIRECTORY_NAME]', 'Run the game in DIRECTORY_NAME in a web server'
      option :browser, type: :boolean, aliases: :b, desc: 'Open a browser when the server starts'
      def server(directory_name = '.')
        Gamefic::Sdk::Server.set :source_dir, directory_name
        Gamefic::Sdk::Server.set :browser, options[:browser]
        pub = File.join(directory_name, 'release', 'sinatra').gsub(/\\/, '/')
        Gamefic::Sdk::Server.set :public_folder, pub
        Gamefic::Sdk::Server.run!
      end

      desc 'build [DIRECTORY_NAME]', 'Build the game for specified platforms in DIRECTORY_NAME'
      option :quiet, type: :boolean, aliases: :q, desc: 'Suppress output'
      def build(directory_name = '.')
        Gamefic::Sdk::Build.release(directory_name, options[:quiet])
      end

      desc 'clean [DIRECTORY_NAME]', 'Perform cleanup of DIRECTORY_NAME'
      def clean(directory_name = '.')
        Gamefic::Sdk::Build.clean(directory_name)
      end

      desc 'import [DIRECTORY_NAME]', 'Copy external scripts to the project'
      option :quiet, type: :boolean, aliases: :q, desc: 'Suppress output'
      def import(directory_name = '.')
        config = Gamefic::Sdk::Config.load directory_name
        FileUtils.remove_entry_secure config.import_path if File.exist?(config.import_path)
        FileUtils.mkdir_p config.import_path
        paths = [config.script_path, Gamefic::Sdk::GLOBAL_SCRIPT_PATH]
        plot = Gamefic::Sdk::Debug::Plot.new Source::File.new(*paths)
        plot.script 'main'
        plot.imported_scripts.each { |s|
          next unless s.absolute_path.start_with?(Gamefic::Sdk::GLOBAL_SCRIPT_PATH)
          src = File.absolute_path(s.absolute_path)
          dst = File.absolute_path(File.join(directory_name, 'imports', "#{s.path}.plot.rb"))
          next if src == dst
          puts "Importing #{s.path}" unless options[:quiet]
          FileUtils.mkdir_p(File.dirname(dst))
          FileUtils.cp_r(src, dst)
        }
      end

      desc 'default-config [DIRECTORY_NAME]', 'Create or overwrite config.yml with default values'
      def default_config(directory_name = '.')
        File.open(File.join(directory_name, 'config.yml'), 'w') do |file|
          file << Gamefic::Sdk::Config.generate
        end
        puts "Default config.yml created."
      end

      desc 'webskins', 'List the available skins for the Web platform'
      def webskins
        Dir[File.join(Gamefic::Sdk::HTML_TEMPLATE_PATH, 'skins', '*')].sort.each { |d|
          puts File.basename(d)
        }
      end

      desc 'script [PATH]', 'List or document the scripts in the SDK'
      def script path = nil
        if path.nil?
          s = []
          Dir[File.join GLOBAL_SCRIPT_PATH, '**', '*.rb'].each { |f|
            c = File.read(f)
            c.each_line { |l|
              match = l.match(/[\s]*#[\s]*@gamefic.script[ ]+([a-z0-9\/]+)/)
              unless match.nil?
                s.push(match[1])
              end
            }
          }
          puts s.sort.join("\n")
        else
          document_script path
        end
      end

      private

      def document_script path
        f = File.join(GLOBAL_SCRIPT_PATH, "#{path}.plot.rb")
        if File.exist?(f)
          c = File.read(f)
          doc = ''
          in_comment = false
          c.each_line { |l|
            if in_comment
              break unless l.start_with?('#')
              doc += "#{l[2..-1]}"
            else
              match = l.match(/[\s]*#[\s]*@gamefic.script[ ]+([a-z0-9\/]+)/)
              in_comment = true unless match.nil?
            end
          }
          if in_comment
            puts ''
            puts path
            puts ''
            puts doc unless doc == ''
            puts '' unless doc == ''
          else
            puts "Path '#{path}' is not documented."
          end
        else
          puts "Script path '#{path}' does not exist."
        end
      end
    end
  end
end
