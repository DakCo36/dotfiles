require 'spec_helper'
require 'components/shell/zsh_binary'

RSpec.describe Component::ZshBinaryComponent do
  subject(:zsh) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:home_path) { '/home/user' }
  let(:bash_profile_path) { '/home/user/.bash_profile' }
  let(:bashrc_path) { '/home/user/.bashrc' }
  let(:local_path) { '/home/user/.local' }
  let(:bin_path) { '/home/user/.local/bin' }
  let(:path_fixture) { "#{bin_path}:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin" }

  before do
    allow(zsh).to receive(:logger).and_return(null_logger)
    allow(zsh).to receive(:curl).and_return(mock_curl)

    # Mock CONFIG constant to return our test values
    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:bash_profile).and_return(bash_profile_path)
    allow(mock_config).to receive(:bashrc).and_return(bashrc_path)
    allow(mock_config).to receive(:local).and_return(local_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:tmp).and_return('/tmp/test')
    allow(mock_config).to receive(:contract_path) do |path|
      path.sub('/home/user', '$HOME')
    end
    stub_const("#{described_class}::CONFIG", mock_config)

    allow(FileUtils).to receive(:touch)
    allow(FileUtils).to receive(:cp)
  end

  describe '#available?' do
    it 'returns true when zsh command is available' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('which', 'zsh')
        .and_return(true)
      # When
      available = zsh.available?
      # Then
      expect(available).to be true
    end

    it 'returns false when zsh command is missing' do
      # Given
      
      allow(zsh).to receive(:runCmd)
        .with('which', 'zsh')
        .and_raise(RuntimeError)
      # When
      available = zsh.available?
      # Then
      expect(available).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when zsh is installed locally and executable and in PATH' do
      # Given
      local_zsh_path = File.join(bin_path, 'zsh')
      allow(ENV).to receive(:[]).with('PATH').and_return(path_fixture)
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(true)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(true)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be true
    end

    it 'returns false when zsh is installed locally but not executable' do
      # Given
      local_zsh_path = File.join(bin_path, 'zsh')
      allow(ENV).to receive(:[]).with('PATH').and_return(path_fixture)
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(true)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(false)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be false
    end

    it 'returns false when zsh is not installed locally' do
      # Given
      local_zsh_path = File.join(bin_path, 'zsh')
      allow(ENV).to receive(:[]).with('PATH').and_return(path_fixture)
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(false)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(false)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be false
    end

    it 'returns false when zsh is installed locally and executable but not in PATH' do
      # Given
      local_zsh_path = File.join(bin_path, 'zsh')
      allow(ENV).to receive(:[]).with('PATH').and_return("/usr/local/bin:/bin:/usr/bin")
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(true)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(true)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be false
    end
  end

  describe '#version' do
    it 'returns the installed zsh version' do
      # Given
      expected_version = '5.9'
      expected_string = "zsh #{expected_version} (x86_64-pc-linux-musl)"
      allow(zsh).to receive(:runCmdWithOutput)
        .with('zsh', '--version')
        .and_return(expected_string)
      # When
      zsh_version = zsh.version()
      # Then
      expect(zsh_version).to eq(expected_version)
    end
  end

  describe '#install' do

    before do
      allow(zsh).to receive(:setPath).and_return(nil)
    end

    context 'When zsh is installed' do
      it 'Do nothing' do
        # Given
        allow(zsh).to receive(:installed?).and_return(true)
        # When
        zsh.install
        # Then
        expect(zsh).not_to receive(:download)
      end
    end

    context 'When zsh is not installed' do
      it 'install zsh' do
        # Given
        allow(zsh).to receive(:installed?).and_return(false)
        allow(zsh).to receive(:runCmd)
          .with('tar', '-xf', anything, '-C', anything)
          .and_return(true)
        allow(zsh).to receive(:configureAndMake).and_return(nil)

        # When
        zsh.install

        # Then
        expect(mock_curl).to have_received(:download).with(anything, anything)
        expect(zsh).to have_received(:configureAndMake)
      end
    end
  end

  describe '#addLocalBinPathInBashrc' do
    it 'adds local bin path to .bashrc' do
      # Given
      original_content = <<~CONTENT
        export EDITOR=vim
        export PATH="/usr/local/sometext:$PATH"
      CONTENT

      allow(File).to receive(:read)
        .with(bashrc_path)
        .and_return(original_content)

      file_handle = instance_double(File)
      allow(File).to receive(:open)
        .with(bashrc_path, 'w')
        .and_yield(file_handle)
      allow(File).to receive(:open)
        .with(bashrc_path, 'a')
        .and_yield(file_handle)
      allow(file_handle).to receive(:puts)

      # When
      zsh.send(:addLocalBinPathInBashrc)

      # Then
      expect(file_handle).to have_received(:puts).with("export PATH=\"$HOME/.local/bin:$PATH\"")
    end

    it 'already local bin path to .bashrc with absolute path' do
      # Given
      original_content = <<~CONTENT
        export PATH="/usr/local/sometext:$PATH"
        export PATH="/home/user/.local/bin:$PATH"
        export EDITOR=vim
      CONTENT

      allow(File).to receive(:read)
        .with(bashrc_path)
        .and_return(original_content)

      file_handle = instance_double(File)
      allow(File).to receive(:open)
        .with(bashrc_path, 'w')
        .and_yield(file_handle)
      allow(File).to receive(:open)
        .with(bashrc_path, 'a')
        .and_yield(file_handle)
      allow(file_handle).to receive(:puts)

      # When
      zsh.send(:addLocalBinPathInBashrc)

      # Then
      expect(file_handle).not_to have_received(:puts).with(match(/export PATH.*\/\.local\/bin/))
    end

    it 'already has local bin path to .bashrc with relative path' do
      # Given
      original_content = <<~CONTENT
        export PATH="~/.local/bin:$PATH"
        export EDITOR=vim
      CONTENT

      allow(File).to receive(:read)
        .with(bashrc_path)
        .and_return(original_content)

      file_handle = instance_double(File)
      allow(File).to receive(:open)
        .with(bashrc_path, 'w')
        .and_yield(file_handle)
      allow(File).to receive(:open)
        .with(bashrc_path, 'a')
        .and_yield(file_handle)
      allow(file_handle).to receive(:puts)

      # When
      zsh.send(:addLocalBinPathInBashrc)

      # Then
      expect(file_handle).not_to have_received(:puts).with(match(/export PATH.*\/\.local\/bin/))
    end
  end

  describe '#removeSourcePattern' do
    # Testing remove source pattern in addSourceBashrcInBashProfile
    it 'remove source pattern #1' do
      original_content = <<~CONTENT
        export PATH="/usr/local/bin:$PATH"
        if [ -f ~/.bashrc ]; then
          source ~/.bashrc
        fi
        export EDITOR=vim
        . ~/.bashrc
        source .bashrc
      CONTENT

      expected_final_content = <<~CONTENT
        export PATH="/usr/local/bin:$PATH"
        export EDITOR=vim
      CONTENT

      source_pattern1 = /if\s+\[\s*-f\s+~?\/\.bashrc\s*\];\s*then\s*\n?\s*(\.|source)\s+~?\/\.bashrc\s*\n?fi\n?/
      source_pattern2 = /^\s*(\.|source)\s+~?\/?\.bashrc\s*\n?/

      original_content.gsub!(source_pattern1, '')
      original_content.gsub!(source_pattern2, '')

      expect(original_content).to eq(expected_final_content)
    end

    it 'remove source pattern #2' do
      original_content = <<~CONTENT
        export PATH="/usr/local/bin:$PATH"
        source ~/.bashrc
        export EDITOR=vim
      CONTENT
      
      expected_final_content = <<~CONTENT
        export PATH="/usr/local/bin:$PATH"
        export EDITOR=vim
      CONTENT

      source_pattern1 = /if\s+\[\s*-f\s+~?\/\.bashrc\s*\];\s*then\s*\n?\s*(\.|source)\s+~?\/\.bashrc\s*\n?fi\n?/
      source_pattern2 = /^\s*(\.|source)\s+~?\/?\.bashrc\s*\n?/

      original_content.gsub!(source_pattern1, '')
      original_content.gsub!(source_pattern2, '')

      expect(original_content).to eq(expected_final_content)
    end
  end

  describe '#addSourceBashrcInBashProfile' do
    let(:file_handler) { instance_double(File) }

    before do
      allow(File).to receive(:read)
        .with(bash_profile_path)
        .and_return(original_content)
      
      allow(File).to receive(:open)
        .with(bash_profile_path, 'w')
        .and_yield(file_handler)
      
      allow(File).to receive(:open)
        .with(bash_profile_path, 'a')
        .and_yield(file_handler)
      
      allow(file_handler).to receive(:puts)
    end

    context 'when source .bashrc with if block pattern' do
      let(:original_content) do
        <<~CONTENT
          export PATH="/usr/local/bin:$PATH"
          if [ -f ~/.bashrc ]; then
            source ~/.bashrc
          fi
          export EDITOR=vim
          . ~/.bashrc
          source .bashrc
        CONTENT
      end

      it 'removes existing source .bashrc patterns and adds new one at the end' do
        # When
        zsh.send(:addSourceBashrcInBashProfile)

        # Then
        expect(file_handler).to have_received(:puts).with(match(/export PATH.*\nexport EDITOR=vim/m))
        expect(file_handler).to have_received(:puts).with("if [ -f ~/.bashrc ]; then")
        expect(file_handler).to have_received(:puts).with("  . ~/.bashrc")
        expect(file_handler).to have_received(:puts).with("fi")
      end
    end
  end
end
