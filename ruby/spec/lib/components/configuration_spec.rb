require 'rspec'
require 'spec_helper'
require 'components/configuration'

RSpec.describe Components::Configuration do
  # Given
  let(:config) { Components::Configuration.instance }

  context 'when home directory is not changed' do
    it 'return user home directory' do
      # When
      # Then
      expect(config.home).to eq(Dir.home)
    end

    it 'allows setting a new home directory' do
      # Given
      new_home = '/tmp'
      # When
      config.home = new_home
      # Then
      expect(config.home).to eq(new_home)
    end
  end
end
