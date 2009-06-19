require File.dirname(__FILE__) + '/../../rails/version' unless defined?(Rails::VERSION)
require File.dirname(__FILE__) + '/../base'
require 'digest/md5' 
require 'active_support/secure_random'

module Rails::Generators
  class App < Base
    DATABASES = %w( mysql oracle postgresql sqlite2 sqlite3 frontbase ibm_db )

    namespace :rails
    add_shebang_option!

    argument :app_path, :type => :string

    class_option :database, :type => :string, :aliases => "-d", :default => "sqlite3",
                            :desc => "Preconfigure for selected database (options: #{DATABASES.join('/')})"

    class_option :freeze, :type => :boolean, :aliases => "-F", :default => false,
                          :desc => "Freeze Rails in vendor/rails from the gems"

    class_option :template, :type => :string, :aliases => "-m",
                            :desc => "Path to an application template (can be a filesystem path or URL)."

    class_option :with_dispatchers, :type => :boolean, :aliases => "-D", :default => false,
                                    :desc => "Add CGI/FastCGI/mod_ruby dispatchers code"

    class_option :no_activerecord, :type => :boolean, :aliases => "-A", :default => false,
                                   :desc => "Do not generate ActiveRecord files"

    class_option :no_testunit, :type => :boolean, :aliases => "-U", :default => false,
                               :desc => "Do not generate TestUnit files"

    class_option :no_prototype, :type => :boolean, :aliases => "-P", :default => false,
                                :desc => "Do not generate Prototype files"

    # Add Rails options
    #
    class_option :version, :type => :boolean, :aliases => "-v", :group => :rails,
                           :desc => "Show Rails version number and quit"

    class_option :help, :type => :boolean, :aliases => "-h", :group => :rails,
                        :desc => "Show this help message and quit"

    def initialize(*args)
      super
      if !options[:no_activerecord] && !DATABASES.include?(options[:database])
        raise Error, "Invalid value for --database option. Supported for preconfiguration are: #{DATABASES.join(", ")}."
      end
    end

    def create_root
      self.root = File.expand_path(app_path, root)
      empty_directory '.'

      app_name # Sets the app name
      FileUtils.cd(root)
    end

    def create_root_files
      copy_file "Rakefile"
      copy_file "README"
    end

    def create_app_files
      directory "app"
    end

    def create_config_files
      empty_directory "config"

      inside "config" do
        copy_file "boot.rb"
        copy_file "routes.rb"
        template  "environment.rb"

        directory "environments"
        directory "initializers"
        directory "locales"
      end
    end

    def create_activerecord_files
      return if options[:no_activerecord]
      template "config/databases/#{options[:database]}.yml", "config/database.yml"
    end

    def create_db_files
      directory "db"
    end

    def create_doc_files
      directory "doc"
    end

    def create_lib_files
      empty_directory "lib"
      empty_directory "lib/tasks"
    end

    def create_log_files
      empty_directory "log"

      inside "log" do
        %w( server production development test ).each do |file|
          create_file "#{file}.log"
          chmod "#{file}.log", 0666, false
        end
      end
    end

    def create_public_files
      directory "public", "public", false # Non-recursive. Do small steps, so anyone can overwrite it.
    end

    def create_dispatch_files
      return unless options[:with_dispatchers]

      copy_file "dispatchers/config.ru", "config.ru"

      template "dispatchers/dispatch.rb", "public/dispatch.rb"
      chmod "public/dispatch.rb", 0755, false

      template "dispatchers/dispatch.rb", "public/dispatch.cgi"
      chmod "public/dispatch.cgi", 0755, false

      template "dispatchers/dispatch.fcgi", "public/dispatch.fcgi"
      chmod "public/dispatch.fcgi", 0755, false
    end

    def create_public_image_files
      directory "public/images"
    end

    def create_public_stylesheets_files
      directory "public/stylesheets"
    end

    def create_prototype_files
      return if options[:no_prototype]
      directory "public/javascripts"
    end

    def create_script_files
      directory "script"
      chmod "script", 0755, false
    end

    def create_test_files
      return if options[:no_testunit]
      directory "test"
    end

    def create_tmp_files
      empty_directory "tmp"

      inside "tmp" do
        %w(sessions sockets cache pids).each do |dir|
          empty_directory dir
        end
      end
    end

    def create_vendor_files
      empty_directory "vendor/plugins"
    end

    def apply_rails_template
      apply options[:template] if options[:template]
    rescue LoadError, Errno::ENOENT => e
      raise "The template [#{template}] could not be loaded. Error: #{e}"
    end

    def freeze?
      freeze! if options[:freeze]
    end

    protected

      def app_name
        @app_name ||= File.basename(root)
      end

      def app_secret
        ActiveSupport::SecureRandom.hex(64)
      end

      def mysql_socket
        @mysql_socket ||= [
          "/tmp/mysql.sock",                        # default
          "/var/run/mysqld/mysqld.sock",            # debian/gentoo
          "/var/tmp/mysql.sock",                    # freebsd
          "/var/lib/mysql/mysql.sock",              # fedora
          "/opt/local/lib/mysql/mysql.sock",        # fedora
          "/opt/local/var/run/mysqld/mysqld.sock",  # mac + darwinports + mysql
          "/opt/local/var/run/mysql4/mysqld.sock",  # mac + darwinports + mysql4
          "/opt/local/var/run/mysql5/mysqld.sock",  # mac + darwinports + mysql5
          "/opt/lampp/var/mysql/mysql.sock"         # xampp for linux
        ].find { |f| File.exist?(f) } unless RUBY_PLATFORM =~ /(:?mswin|mingw)/
      end
  end
end
