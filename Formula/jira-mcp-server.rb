class JiraMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Jira MCP server with Firefox cookie bridge extension"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "aa7694930f6731e5c9f6f977e83c07cc103261b7a5d90d28a042da981313c2ea"
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

    # Pre-populate from JIRA_URL env var if provided (first install only)
    jira_url = ENV["JIRA_URL"]
    if jira_url && !(etc/"jira-mcp-server/.env.local").exist?
      env_content = File.read(".env.local.example")
      env_content.gsub!("https://jira.example.com", jira_url)
      (etc/"jira-mcp-server/.env.local").write(env_content)
    end

    # If config exists (upgrade or JIRA_URL provided), build the extension
    if (etc/"jira-mcp-server/.env.local").exist?
      ln_sf etc/"jira-mcp-server/.env.local", libexec/".env.local"
      cd libexec do
        system "make", "build"
        system "make", "xpi"
        system "make", "install"
      end
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

        Install the .xpi in Firefox Developer Edition:
          about:config -> set xpinstall.signatures.required to false
          about:addons -> gear icon -> Install Add-on From File...
          Select: #{opt_libexec}/build/jira-cookie-bridge.xpi

        Configure your MCP client:

          Claude Code (project):  Add to .mcp.json:
            { "mcpServers": { "jira": { "command": "jira-mcp-server" } } }

          Claude Code (global):
            claude mcp add --scope user jira jira-mcp-server

          Claude Desktop:  Add to ~/Library/Application Support/Claude/claude_desktop_config.json:
            { "mcpServers": { "jira": { "command": "#{opt_bin}/jira-mcp-server" } } }

        Config: #{etc}/jira-mcp-server/.env.local (survives brew upgrade)
      EOS
    else
      <<~EOS
        To complete setup:

        1. Configure your Jira instance:
             cp #{opt_libexec}/.env.local.example #{etc}/jira-mcp-server/.env.local
             $EDITOR #{etc}/jira-mcp-server/.env.local

        2. Build the extension and install the native messaging host:
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

        Tip: To skip manual config, reinstall with:
             JIRA_URL=https://jira.example.com brew reinstall posalex/tap/jira-mcp-server
      EOS
    end
  end

  test do
    assert_predicate bin/"jira-mcp-server", :executable?
  end
end
