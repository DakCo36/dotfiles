require 'spec_helper'
require 'components/fetch/git'

RSpec.describe Component::GitComponent do
  subject(:git) { described_class.instance }

  describe '#exist?' do
    it 'returns true when git command is available' do
      allow(git)
        .to receive(:system)
        .with('git', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)

      expect(git.exist?).to be true
    end

    it 'returns false when git command is missing' do
      allow(git)
        .to receive(:system)
        .with('git', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)
      
      expect(git.exist?).to be false
    end
  end

  describe '#version' do
    it 'returns the installed git version' do
      allow(git)
        .to receive(:`)
        .with('git --version 2>&1')
        .and_return("git version 2.30.0\n")
      system('true')

      expect(git.version).to eq('2.30.0')
    end

    it 'returns nil when git is not installed' do
      allow(git)
        .to receive(:`)
        .with('git --version 2>&1')
        .and_raise(Errno::ENOENT)

      expect(git.version).to be_nil
    end
  end

  describe '#clone' do
    let(:url) { 'https://github.com/dakco36/dotfiles.git' }
    let(:destination) { '/tmp/dotfiles' }

    context 'when git is installed' do
      before do
        allow(git).to receive(:exists?).and_return(true)
        allow(git).to receive(:runCmd)
          .with('git', 'clone', '--depth', '1', url, destination)
          .and_return(['', '', 0])
      end

      it 'clones the repo to the destination' do
        expect { git.clone(url, destination) }.not_to raise_error
        expect(git).to have_received(:runCmd)
          .with('git', 'clone', '--depth', '1', url, destination)
      end
    end

    context 'when git is not installed' do
      before do
        allow(git).to receive(:exists?).and_return(false)
      end

      it 'raises an error' do
        expect { git.clone(url, destination) }
          .to raise_error(RuntimeError, 'git is not installed')
      end
    end
  end
end
