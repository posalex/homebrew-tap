class JiraMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Jira MCP server with Firefox cookie bridge and HTTP proxy for IDEs"
  homepage "https://github.com/posalex/jira-mcp-server"
  url "https://github.com/posalex/jira-mcp-server/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "f8b78a920fc92542c1d0625f5a46ecf3f773fb64ee0dd351644304a8309f2274"
  license "GPL-3.0-or-later"

  depends_on "python@3.12"

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install "httpx"
    venv.pip_install "fastmcp"

    libexec.install "server.py"
    libexec.install "proxy.py"
    libexec.install "native-host"
    libexec.install "firefox-extension"
    libexec.install "launchd"
    libexec.install "Makefile"
    libexec.install ".env.local.example"

    # Config lives in etc/ so it survives brew upgrade
    (etc/"jira-mcp-server").mkpath

    # Pre-populate from env var if provided (first install only)
    jira_url = ENV["HOMEBREW_JIRA_URL"] || ENV["JIRA_URL"]
    if jira_url && !(etc/"jira-mcp-server/.env.local").exist?
      env_content = File.read(libexec/".env.local.example")
      env_content.gsub!("https://jira.example.com", jira_url)
      (etc/"jira-mcp-server/.env.local").write(env_content)
    end

    # MCP server wrapper
    (bin/"jira-mcp-server").write <<~EOS
      #!/bin/bash
      export ENV_FILE="#{etc}/jira-mcp-server/.env.local"
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
    chmod 0755, bin/"jira-mcp-server"

    # Proxy wrapper
    (bin/"jira-proxy").write <<~EOS
      #!/bin/bash
      export ENV_FILE="#{etc}/jira-mcp-server/.env.local"
      exec "#{libexec}/bin/python3" "#{libexec}/proxy.py" "$@"
    EOS
    chmod 0755, bin/"jira-proxy"
  end

  def post_install
    if (etc/"jira-mcp-server/.env.local").exist?
      ln_sf etc/"jira-mcp-server/.env.local", libexec/".env.local"
      system "make", "-C", libexec, "build"
      system "make", "-C", libexec, "xpi"
    end
  end

  def caveats
    if (etc/"jira-mcp-server/.env.local").exist?
      <<~EOS
        Extension built automatically.

        Install the native messaging host (first time only):
          make -C #{opt_libexec} install

        Install the .xpi in Firefox Developer Edition (first time only):
          about:config -> set xpinstall.signatures.required to false
          about:addons -> gear icon -> Install Add-on From File...
          Select: #{opt_libexec}/build/jira-cookie-bridge.xpi

        HTTP Proxy for PhpStorm / IntelliJ:
          jira-proxy                          # run in foreground
          make -C #{opt_libexec} proxy-start  # install as macOS service
          PhpStorm -> Settings -> Tools -> Tasks -> Servers -> Jira
            URL: http://localhost:9778   Username/Password: anything

        MCP client config (first time only):

          Claude Code (project):  Add to .mcp.json:
            { "mcpServers": { "jira": { "command": "jira-mcp-server" } } }

          Claude Code (global):
            claude mcp add --scope user jira jira-mcp-server

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
    assert_predicate bin/"jira-proxy", :executable?
  end
end
