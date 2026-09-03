cask "claude-usage" do
  version "1.1.1"
  sha256 "87ab753263c55dcdebf208d7b7f079a10f9218ea079f58e73c74c3d737c1a4b9"

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
