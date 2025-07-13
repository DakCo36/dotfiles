#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'

class TestLogger
  include Loggable

  def test_log(msg)
    logger.info(msg)
  end
end

if __FILE__ == $0
  t = TestLogger.new
  t.test_log("테스트 메시지입니다!")
end
