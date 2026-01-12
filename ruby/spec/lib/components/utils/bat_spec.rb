require 'spec_helper'
require 'components/utils/bat'

RSpec.describe Component::BatComponent do
  subject(:bat) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:bin_path) { '/home/user/.local/bin' }
  let(:man1_path) { '/home/user/.local/share/man/man1' }
  let(:zsh_completions_path) { '/home/user/.local/share/zsh/site-functions' }
  let(:bash_completions_path) { '/home/user/.local/share/bash-completion/completions' }

  before do
    allow(bat).to receive(:logger).and_return(null_logger)
    allow(bat).to receive(:curl).and_return(mock_curl)
    allow(bat).to receive(:tar).and_return(mock_tar)
    allow(bat).to receive(:github).and_return(mock_github)

    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:tmp).and_return('/tmp/test')
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)
    
    stub_const("#{described_class}::CONFIG", mock_config)
  end

  describe '#available?' do
    it 'returns true when bat command is available' do
      # Give
      allow(bat)
        .to receive(:system)
        .with('bat', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)
      
      # When
      available = bat.available?
      
      # Then
      expect(available).to be true
    end

    it 'returns false when bat command is missing' do
      # Given
      allow(bat)
        .to receive(:system)
        .with('bat', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)
      # When
      available = bat.available?

      # Then
      expect(available).to be false
    end
  end
end 
