require 'singleton'

module Components
  class Configuration
    include Singleton
    attr_accessor :home
    attr_accessor :local
    attr_accessor :bin

    def initialize
      @home = Dir.home
      @local = Dir.home + '/.local'
      @bin = local + '/bin'
    end
  end
end
