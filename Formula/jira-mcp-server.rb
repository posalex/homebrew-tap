class JiraMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Jira MCP server with Firefox cookie bridge extension"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "ad15502131f14d5e5bda34b8f7e824ba25b31bb70b609060e1d624742ba4daa7"
  license "GPL-3.0-or-later"

  depends_on "python@3.12"

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install "httpx"
    venv.pip_install "fastmcp"

    libexec.install "server.py"
    libexec.install "native-host"
    libexec.install "firefox-extension"
    libexec.install "Makefile"
    libexec.install ".env.local.example"

    # Copy example config so make build can render templates
    cd libexec do
      cp ".env.local.example", ".env.local"
      system "make", "build"
      system "make", "xpi"
    end

    (bin/"jira-mcp-server").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
    chmod 0755, bin/"jira-mcp-server"
  end

  def caveats
    <<~EOS
      To complete setup:

      1. Copy the example config and edit it:
           cp #{libexec}/.env.local.example #{libexec}/.env.local
           $EDITOR #{libexec}/.env.local

      2. Install the native messaging host for Firefox:
           cd #{libexec} && make install

      3. Load the Firefox extension in Firefox Developer Edition:
           about:config -> set xpinstall.signatures.required to false
           about:addons -> gear icon -> Install Add-on From File...
           Select: #{libexec}/build/jira-cookie-bridge.xpi

      4. Configure your MCP client to use:
           #{bin}/jira-mcp-server
    EOS
  end

  test do
    assert_predicate bin/"jira-mcp-server", :executable?
  end
end
