cask "claude-usage" do
  version "1.0.0"
  sha256 "42a29ed335becb81a364c9472941b16b654251e10cac6ad3fae8cebeb73db349"

  url "https://github.com/posalex/ClaudeUsage/releases/download/v#{version}/ClaudeUsage.zip"
  name "Claude Usage"
  desc "macOS menu bar widget showing claude.ai subscription usage and rate limits"
  homepage "https://github.com/posalex/ClaudeUsage"

  depends_on macos: ">= :ventura"

  app "ClaudeUsage.app"

  caveats <<~EOS
    The app is not notarized. macOS will block it on first launch.
    Run this to allow it:
      xattr -d com.apple.quarantine /Applications/ClaudeUsage.app
  EOS

  zap trash: [
    "~/Library/Preferences/com.github.posalex.claudeusage.plist",
    "~/Library/Application Support/ClaudeUsage",
  ]
end