cask "claude-usage" do
  version "1.1.4"
  sha256 "b597f7917547498fba7b770afab9a6bb18dcd7495e1a73f9b35fc110cbeb0ac6"

  url "https://github.com/posalex/ClaudeUsage/releases/download/v#{version}/ClaudeUsage.zip"
  name "Claude Usage"
  desc "macOS menu bar widget showing Claude, Fable, and Codex usage limits"
  homepage "https://github.com/posalex/ClaudeUsage"

  depends_on macos: :sequoia

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
