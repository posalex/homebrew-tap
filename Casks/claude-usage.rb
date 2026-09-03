cask "claude-usage" do
  version "1.1.2"
  sha256 "7f161ab9c23caea5bf532d59ad3c27fa9aa039ca7fa8b8fd7d6b9d4a7cd43c65"

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
