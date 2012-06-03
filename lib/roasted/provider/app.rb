require 'tempfile'
require 'plist'
require 'digest'

module Roasted
  class Provider
    class App
      attr_accessor :app
      attr_accessor :action
      attr_accessor :options
      
      attr_accessor :source
      attr_accessor :type
      attr_accessor :checksum
      attr_accessor :accept_eula
      attr_accessor :installs
      attr_accessor :license
      attr_accessor :domain
      attr_accessor :hooks
      
      def initialize(action, app, options)
        @app = app
        @action = action
        @options = options
        @installs = { :app => @app }
        @hooks = {}
        
        path = File.expand_path(File.join(File.dirname(__FILE__), "app", "#{app.downcase}.rb"))
        @parser = Parser.new(self)
        @parser.instance_eval(File.read(path), path)
      end
      
      def self.create(options)
        action = options.delete(:action)
        app = options.delete(:app)

        # Replace ourself with custom class
        path = File.expand_path(File.join(File.dirname(__FILE__), "app", "#{app.downcase}.rb"))
        raise "Cannot find app provider #{app}" unless File.exists?(path)
        
        new(action, app, options)
      end
      
      # Actions, at this point only install
      def install
        if File.exists?("/Applications/#{@installs[:app]}.app")
          if @installs[:version]
            # Check version
            info = Plist.parse_xml(File.read("/Applications/#{@installs[:app]}.app/Contents/Info.plist"))
            return if info["CFBundleShortVersionString"] >= @installs[:version]
          else
            # No version requested, installs app exists, skipping installation
            return
          end
        end

        puts "Installing #{@app}"
        
        self.send("install_#{self.type}")
        
        # Handle license
        if @options[:license] and @license
          puts "Setting up license"
          if @license[:block]
            @license[:block].call(@options[:license])
          else
            self.send("license_#{@license[:type]}", @options[:license])
          end
        end
        
        # Handle custom functionality
        if @options[:block]
          @parser.instance_eval &@options[:block]
        end
        
        # Hooks
        if @hooks[:after_install]
          @hooks[:after_install].call
        end
      end
      
      def install_zip
        tmp = download_source
        
        # Simple and easy, just extract zip
        system "ditto -x -k '#{tmp.path}' '/Applications/'"
        
        # Cleanup
        tmp.unlink
      end
      
      def install_tbz
        tmp = download_source
        
        # Simple and easy, just extract bzip tar
        system "tar -C '/Applications' -jxf '#{tmp.path}'"
        
        # Cleanup
        tmp.unlink        
      end
      
      def install_dmg
        tmp = download_source

        # Attach it
        needs_eula = system("hdiutil imageinfo #{tmp.path} | grep -q 'Software License Agreement: true'")
        raise "Requires EULA Acceptance; add 'accept_eula' to application resource" if needs_eula and !@accept_eula
        accept_eula_cmd = @accept_eula ? "yes |" : ""
        # require 'pry';binding.pry if needs_eula
        system "#{accept_eula_cmd} hdiutil attach '#{tmp.path}' > /dev/null"
        
        # Get volume path
        hdi = Plist.parse_xml(`hdiutil info -plist`)
        image = hdi["images"].select{|i| i["image-path"] == tmp.path}.first
        mntinfo = image["system-entities"].select{|i| i.has_key?("mount-point")}.first
        mount_point = mntinfo["mount-point"]
        disk = mntinfo["dev-entry"]
        
        # Find app
        Dir["#{mount_point}/*#{@app}*.{app,pkg,mpkg}"].each do |entry|
          type = @apptype || File.extname(entry)[1..-1].to_sym
          case type
          when :app
            system "rsync -aH '#{entry}' '/Applications/'"
          when :pkg
          when :mpkg
            system "sudo installer -pkg '#{entry}' -target /"
          else
            puts "Don't know how to handle entry #{entry}, type #{type}!"
          end
        end

        # Detach
        system("hdiutil detach -quiet '#{mount_point}'")
        
        # Remove image
        tmp.unlink        
      end

      def license_preferences(license)
        domain_exists = system("defaults domains | grep #{@domain} >/dev/null")
        
        if domain_exists
          @license[:options].each do |key, name|
            system "defaults write #{@domain} '#{name}' '#{license[key]}'"
          end
        else
          plist = @license[:options].collect {|key, name| "\"#{name}\" = \"#{license[key]}\";"}.join(" ")
          system "defaults write #{@domain} '{#{plist}}'"
        end
      end
      
      def type
        @type ||= case self.source
        when /zip$/
          :zip
        when /tbz$/
          :tbz
        when /dmg$/
          :dmg
        end
      end
      
      def to_s
        "#{self.class}: #{self.options.inspect}"
      end
      
      private
      def download_source
        # Create temporary path for image
        tmp = Tempfile.new(@app)
        
        # Download image
        system("curl -o #{tmp.path} '#{@source}'")
        
        # Calculate checksum
        checksum = Digest::SHA1.hexdigest(File.read(tmp.path))
        if @checksum != checksum
          puts "Checksum mismatch"
          puts "Source checksum: #{checksum}"
          puts "       Expected: #{@checksum}"
          raise "Checksum mismatch"
        end
        
        return tmp
      end
      
      class Parser
        def initialize(app)
          @app = app
        end
        
        # DSL actions
        def source(source, options = {})
          # version = options[:version] || :default
          @app.source = source
          @app.type = options.delete(:type)
        end
        
        def checksum(checksum)
          @app.checksum = checksum
        end
        
        def accept_eula
          @app.accept_eula = true
        end
        
        def installs(appname, options = {})
          @app.installs = options.merge(:app => appname)
        end
        
        def license(type, options = {}, &block)
          @app.license = {:type => type, :options => options, :block => block}
        end
        
        def defaults(domain)
          @app.domain = domain
        end
        
        def after_install(&block)
          @app.hooks[:after_install] = block
        end
        
        def preferences(prefs)
          domain_exists = system("defaults domains | grep #{@app.domain} >/dev/null")
          
          if domain_exists
            prefs.each do |key, value|
              system "defaults write #{@app.domain} '#{key}' '#{value}'"
            end
          else
            plist = prefs.collect {|key, value| "\"#{key}\" = \"#{value}\";"}.join(" ")
            system "defaults write #{@app.domain} '{#{plist}}'"
          end
        end
      end
    end
  end
end
