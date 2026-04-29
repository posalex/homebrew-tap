class ConfluenceMcpServer < Formula
  include Language::Python::Virtualenv

  desc "Confluence MCP server with Firefox cookie bridge and HTTP proxy for IDEs"
  homepage "https://github.com/posalex/confluence-mcp-server"
  url "https://github.com/posalex/confluence-mcp-server/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "895911724e1995c78394a53a6207ceaf46e98e7764ced378f3c4c899324f2d21"
  license "GPL-3.0-or-later"

  depends_on "python@3.12"

  def install
    venv = virtualenv_create(libexec, "python3.12")
    system libexec/"bin/python3", "-m", "pip", "install", "httpx", "fastmcp"

    libexec.install "server.py"
    libexec.install "proxy.py"
    libexec.install "native-host"
    libexec.install "firefox-extension"
    libexec.install "launchd"
    libexec.install "Makefile"
    libexec.install ".env.local.example"

    # Config lives in etc/ so it survives brew upgrade
    (etc/"confluence-mcp-server").mkpath

    # Pre-populate from env var if provided (first install only)
    confluence_url = ENV["HOMEBREW_CONFLUENCE_URL"] || ENV["CONFLUENCE_URL"]
    if confluence_url && !(etc/"confluence-mcp-server/.env.local").exist?
      env_content = File.read(libexec/".env.local.example")
      env_content.gsub!("https://confluence.example.com", confluence_url)
      (etc/"confluence-mcp-server/.env.local").write(env_content)
    end

    # MCP server wrapper
    (bin/"confluence-mcp-server").write <<~EOS
      #!/bin/bash
      export ENV_FILE="#{etc}/confluence-mcp-server/.env.local"
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
    chmod 0755, bin/"confluence-mcp-server"

    # Proxy wrapper
    (bin/"confluence-proxy").write <<~EOS
      #!/bin/bash
      export ENV_FILE="#{etc}/confluence-mcp-server/.env.local"
      exec "#{libexec}/bin/python3" "#{libexec}/proxy.py" "$@"
    EOS
    chmod 0755, bin/"confluence-proxy"
  end

  def post_install
    if (etc/"confluence-mcp-server/.env.local").exist?
      ln_sf etc/"confluence-mcp-server/.env.local", libexec/".env.local"
      system "make", "-C", libexec, "build"
      system "make", "-C", libexec, "xpi"
    end

    # Restart proxy if running (so it picks up the new code)
    # Kill the process — KeepAlive in the plist will auto-restart it
    system "pkill", "-f", "proxy\\.py"
  end

  def caveats
    if (etc/"confluence-mcp-server/.env.local").exist?
      <<~EOS
        Extension built automatically.

        Install the native messaging host (first time only):
          make -C #{opt_libexec} install

        Install the .xpi in Firefox Developer Edition (first time only):
          about:config -> set xpinstall.signatures.required to false
          about:addons -> gear icon -> Install Add-on From File...
          Select: #{opt_libexec}/build/confluence-cookie-bridge.xpi

        HTTP Proxy (cookie injection for arbitrary HTTP clients):
          confluence-proxy                    # run in foreground
          make -C #{opt_libexec} proxy-start  # install as macOS service
          Endpoint: http://localhost:9780     # health: /_proxy/health

        Cookie web UI: http://localhost:9779

        MCP client config (first time only):

          Claude Code (project):  Add to .mcp.json:
            { "mcpServers": { "confluence": { "command": "confluence-mcp-server" } } }

          Claude Code (global):
            claude mcp add --scope user confluence confluence-mcp-server

        Config: #{etc}/confluence-mcp-server/.env.local
      EOS
    else
      <<~EOS
        Run this to configure and build everything:
          HOMEBREW_CONFLUENCE_URL=https://your-confluence-instance.com brew reinstall posalex/tap/confluence-mcp-server
      EOS
    end
  end

  test do
    assert_predicate bin/"confluence-mcp-server", :executable?
    assert_predicate bin/"confluence-proxy", :executable?
  end
end
