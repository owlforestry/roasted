require 'thor'
require 'roasted/roaster'

module Roasted
  class CLI < Thor
    default_task :bootstrap
    
    desc "bootstrap", "Bootstraps current workstation with given roasted description"
    method_option :config, :type => :string, :default => "roastedrc"
    def bootstrap()
      say "Starting bootstrapping..."
      raise "Cannot find roastedrc" unless File.exists?(options[:config])
      
      # Load config file
      Roaster.new(options)
    end
  end
end
