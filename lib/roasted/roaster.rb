require 'roasted/provider/brew'
require 'roasted/provider/app'

module Roasted
  class Roaster
    attr_reader :options
    
    def initialize(options)
      @options = options
      
      # Load DSL
      parser = Parser.new
      parser.instance_eval(File.read(options[:config]), options[:config])
      
      parser.runlist.each do |run|
        # Only action at this point, install
        run.install
      end
    end
    
    class Parser
      attr_reader :runlist
      
      def initialize
        @runlist = []
      end
      
      def brew(formula)
        @runlist << ::Roasted::Provider::Brew.create(:formula => formula)
      end
      
      def app(appname, options = {}, &block)
        @runlist << ::Roasted::Provider::App.create(options.merge({:app => appname, :block => block}))
      end
    end
  end
end