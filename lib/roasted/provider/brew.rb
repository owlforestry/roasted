module Roasted
  class Provider
    class Brew
      attr_accessor :formula
      attr_accessor :action
      attr_accessor :options
      
      def self.create(options)
        return new(options)
      end
      
      def initialize(options)
        @action = options.delete(:action)
        @formula = options.delete(:formula)
        
        @options = options
      end
      
      def install
        # Simple, check if we have brew installed
        install_brew unless File.executable?("/usr/local/bin/brew")
        
        unless File.directory?("/usr/local/Cellar/#{@formula}")
          system("/usr/local/bin/brew install #{@formula}")
        end
      end
      
      def install_brew
        system '/usr/bin/ruby -e "$(/usr/bin/curl -fsSL https://raw.github.com/mxcl/homebrew/master/Library/Contributions/install_homebrew.rb)"'
      end
    end
  end
end
