class JiraMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Jira MCP server with Firefox cookie bridge extension"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "2e7d54643902c34bd2870f7dd0dee65a2492e8ca95c0a4ab73e39291dd7abfd1"
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

    # Pre-populate from JIRA_URL env var if provided
    jira_url = ENV["JIRA_URL"]
    if jira_url && !(etc/"jira-mcp-server/.env.local").exist?
      env_content = File.read(".env.local.example")
      env_content.gsub!("https://jira.example.com", jira_url)
      (etc/"jira-mcp-server/.env.local").write(env_content)
    end

    # Symlink etc config into libexec so Makefile finds it
    libexec.install_symlink etc/"jira-mcp-server/.env.local" if (etc/"jira-mcp-server/.env.local").exist?

    (bin/"jira-mcp-server").write <<~EOS
      #!/bin/bash
      # Load config from Homebrew etc/ (survives upgrades)
      export ENV_FILE="#{etc}/jira-mcp-server/.env.local"
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
    chmod 0755, bin/"jira-mcp-server"
  end

  def caveats
    <<~EOS
      To complete setup:

      1. Configure your Jira instance (skip if you set JIRA_URL during install):
           cp #{opt_libexec}/.env.local.example #{etc}/jira-mcp-server/.env.local
           $EDITOR #{etc}/jira-mcp-server/.env.local

      2. Symlink config and build the extension:
           ln -sf #{etc}/jira-mcp-server/.env.local #{opt_libexec}/.env.local
           cd #{opt_libexec} && make all

      3. Install the .xpi in Firefox Developer Edition:
           about:config -> set xpinstall.signatures.required to false
           about:addons -> gear icon -> Install Add-on From File...
           Select: #{opt_libexec}/build/jira-cookie-bridge.xpi

      4. Configure your MCP client:

         Claude Code (project):  Add to .mcp.json:
           { "mcpServers": { "jira": { "command": "jira-mcp-server" } } }

         Claude Code (global):
           claude mcp add --scope user jira jira-mcp-server

         Claude Desktop:  Add to ~/Library/Application Support/Claude/claude_desktop_config.json:
           { "mcpServers": { "jira": { "command": "#{opt_bin}/jira-mcp-server" } } }

      Tip: To pre-configure, install with:
           JIRA_URL=https://jira.example.com brew install posalex/tap/jira-mcp-server

      Note: Config is stored in #{etc}/jira-mcp-server/ and survives brew upgrade.
            After upgrading, re-run step 2 to rebuild the extension.
    EOS
  end

  test do
    assert_predicate bin/"jira-mcp-server", :executable?
  end
end
