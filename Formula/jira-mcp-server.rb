class JiraMcpServer < Formula
  desc "Jira MCP server with Firefox cookie bridge extension"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "fd30b713ba14af9ff3f5c57783e01bb8c0659a7b439b2820972a2bcb9f96bd81"
  license "GPL-3.0-or-later"

  depends_on "python@3.12"

  def install
    # Create a virtualenv and install Python dependencies
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install "httpx"
    venv.pip_install "fastmcp"

    # Install server and support files
    libexec.install "server.py"
    libexec.install "native-host"
    libexec.install "firefox-extension"
    libexec.install "Makefile"
    libexec.install ".env.local.example"

    # Create wrapper script
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

      3. Load the Firefox extension:
           Firefox -> about:debugging -> Load Temporary Add-on
           Select: #{libexec}/build/extension/manifest.json
           Or with Firefox Developer Edition, install the .xpi directly.

      4. Configure your MCP client to use:
           #{bin}/jira-mcp-server
    EOS
  end

  test do
    assert_predicate bin/"jira-mcp-server", :executable?
  end
end
