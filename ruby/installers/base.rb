class Installer
  def installed?
    raise NotImplementedError
  end

  def install
    raise NotImplementedError
  end
end
