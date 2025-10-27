require 'rspec'
require 'spec_helper'
require 'components/configuration'

RSpec.describe Components::Configuration do
  # Given
  let(:home_path) { '/home/user' }
  let(:config) { Components::Configuration.instance }

  before do
    # Reset singleton before each test
    Singleton.__init__(Components::Configuration)
    allow(Dir).to receive(:home).and_return(home_path)
  end

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

  context '#contract_path' do
    it 'replaces home directory with $HOME' do
      contracted = config.contract_path('/home/user/test')
      expect(contracted).to eq(File.join('$HOME', 'test'))
    end

    it 'returns the original path if home directory is not in the path' do
      expect(config.contract_path('/tmp/test')).to eq('/tmp/test')
    end
  end
end
