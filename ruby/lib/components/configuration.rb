require 'singleton'

module Components
  class Configuration
    include Singleton
    attr_accessor :home

    def initialize
      @home = Dir.home
    end
  end
end
