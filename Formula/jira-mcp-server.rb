class JiraMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Jira MCP server with Firefox cookie bridge extension"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "83e888c7fd6cab20b96fe1f4b337e5bb3e7904cc6e57297c5d86c520789a8238"
  license "GPL-3.0-or-later"

  depends_on "python@3.12"

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install "httpx"
    venv.pip_install "fastmcp"

    # Write .env.local from JIRA_URL env var if provided
    jira_url = ENV["JIRA_URL"]
    if jira_url
      env_content = File.read(".env.local.example")
      env_content.gsub!("https://jira.example.com", jira_url)
      File.write(".env.local", env_content)
    end

    libexec.install "server.py"
    libexec.install "native-host"
    libexec.install "firefox-extension"
    libexec.install "Makefile"
    libexec.install ".env.local.example"
    libexec.install ".env.local" if File.exist?(".env.local")

    (bin/"jira-mcp-server").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
    chmod 0755, bin/"jira-mcp-server"
  end

  def caveats
    <<~EOS
      To complete setup:

      1. Configure your Jira instance (skip if you set JIRA_URL during install):
           cp #{libexec}/.env.local.example #{libexec}/.env.local
           $EDITOR #{libexec}/.env.local

      2. Build the extension and install the native messaging host:
           cd #{libexec} && make all

      3. Install the .xpi in Firefox Developer Edition:
           about:config -> set xpinstall.signatures.required to false
           about:addons -> gear icon -> Install Add-on From File...
           Select: #{libexec}/build/jira-cookie-bridge.xpi

      4. Configure your MCP client to use:
           #{bin}/jira-mcp-server

      Tip: To pre-configure, install with:
           JIRA_URL=https://jira.example.com brew install posalex/tap/jira-mcp-server
    EOS
  end

  test do
    assert_predicate bin/"jira-mcp-server", :executable?
  end
end
