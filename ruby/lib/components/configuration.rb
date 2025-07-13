require 'singleton'
require 'tmpdir'

module Components
  class Configuration
    include Singleton
    attr_accessor :home
    attr_accessor :local
    attr_accessor :bin
    attr_accessor :tmp

    def initialize
      @home = Dir.home
      @local = Dir.home + '/.local'
      @bin = local + '/bin'
      @tmp = Dir.tmpdir + '/' + generateTimestamp()

      FileUtils.mkdir_p(@tmp) unless Dir.exist?(@tmp)
    end

    private
    def generateTimestamp
      Time.now.strftime('%Y%m%d_%H%M%S')
    end
  end
end
