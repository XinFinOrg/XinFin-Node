class XDC < Formula
  desc "XinFin Hybrid Blockchain"
  homepage "https://github.com/XinFinOrg/XDPoS-TestNet-Apothem"
  url "https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git"

  devel do
    url "https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git", :branch => "master"
  end

  # Require El Capitan at least
  depends_on :macos => :el_capitan

  # Is there a better way to ensure that frameworks (IOKit, CoreServices, etc) are installed?
  depends_on :xcode => :build

  depends_on "go" => :build

  def install
    ENV["GOROOT"] = "#{HOMEBREW_PREFIX}/opt/go/libexec"
    system "go", "env" # Debug env
    system "make", "all"
    bin.install "build/bin/evm"
    bin.install "build/bin/xdc"
    bin.install "build/bin/rlpdump"
    bin.install "build/bin/puppeth"
  end

  test do
    system "#{HOMEBREW_PREFIX}/bin/xdc", "--version"
  end
end
