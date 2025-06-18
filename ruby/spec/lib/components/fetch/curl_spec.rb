require 'spec_helper'
require 'components/fetch/curl'

RSpec.describe Component::CurlComponent do
  subject(:curl) { described_class.new }

  describe '#exists?' do
    it 'returns true when curl command is available' do
      allow(curl).to receive(:system)
        .with('curl', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)

      expect(curl.exists?).to be true
    end

    it 'returns false when curl command is missing' do
      allow(curl).to receive(:system)
        .with('curl', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)

      expect(curl.exists?).to be false
    end
  end

  describe '#version' do
    it 'returns the installed curl version' do
      allow(curl).to receive(:`).with('curl --version 2>&1').and_return("curl 8.0.0 (x86_64-pc-linux-gnu)\n")
      system('true') # ensure $CHILD_STATUS is successful

      expect(curl.version).to eq('8.0.0')
    end

    it 'returns nil when curl is not installed' do
      allow(curl).to receive(:`).with('curl --version 2>&1').and_raise(Errno::ENOENT)

      expect(curl.version).to be_nil
    end
  end
end
