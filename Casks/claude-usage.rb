cask "claude-usage" do
  version "1.0.0"
  sha256 "1f03e1bbfbe3c344ae09bd1abae287c549d227f89f2406c769203211841a8d15"

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