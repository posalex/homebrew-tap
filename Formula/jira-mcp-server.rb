class JiraMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Jira MCP server with Firefox cookie bridge extension"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "52ec4b0de7a56f09366054b1031d776c9cf0d6d3db5f01c55c4d95aa1846bd74"
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

    # Config lives in etc/ so it survives brew upgrade
    (etc/"jira-mcp-server").mkpath

    # Pre-populate from env var if provided (first install only)
    # Homebrew filters env vars — HOMEBREW_* prefix passes through
    jira_url = ENV["HOMEBREW_JIRA_URL"] || ENV["JIRA_URL"]
    if jira_url && !(etc/"jira-mcp-server/.env.local").exist?
      env_content = File.read(libexec/".env.local.example")
      env_content.gsub!("https://jira.example.com", jira_url)
      (etc/"jira-mcp-server/.env.local").write(env_content)
    end

    # If config exists (upgrade or JIRA_URL provided), build everything
    if (etc/"jira-mcp-server/.env.local").exist?
      ln_sf etc/"jira-mcp-server/.env.local", libexec/".env.local"
      system "make", "-C", libexec, "build"
      system "make", "-C", libexec, "xpi"
      system "make", "-C", libexec, "install"
    end

    (bin/"jira-mcp-server").write <<~EOS
      #!/bin/bash
      export ENV_FILE="#{etc}/jira-mcp-server/.env.local"
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
    chmod 0755, bin/"jira-mcp-server"
  end

  def caveats
    if (etc/"jira-mcp-server/.env.local").exist?
      <<~EOS
        Extension built and native host installed automatically.

        Install the .xpi in Firefox Developer Edition (first time only):
          about:config -> set xpinstall.signatures.required to false
          about:addons -> gear icon -> Install Add-on From File...
          Select: #{opt_libexec}/build/jira-cookie-bridge.xpi

        Configure your MCP client (first time only):

          Claude Code (project):  Add to .mcp.json:
            { "mcpServers": { "jira": { "command": "jira-mcp-server" } } }

          Claude Code (global):
            claude mcp add --scope user jira jira-mcp-server

          Claude Desktop:  Add to ~/Library/Application Support/Claude/claude_desktop_config.json:
            { "mcpServers": { "jira": { "command": "#{opt_bin}/jira-mcp-server" } } }

        Config: #{etc}/jira-mcp-server/.env.local
      EOS
    else
      <<~EOS
        Run this to configure and build everything:
          HOMEBREW_JIRA_URL=https://your-jira-instance.com brew reinstall posalex/tap/jira-mcp-server
      EOS
    end
  end

  test do
    assert_predicate bin/"jira-mcp-server", :executable?
  end
end
