cask "claude-usage" do
  version "1.1.0"
  sha256 "f4564b21ec9aefe0271dcdbb07cb8901abd8221487445b5433210ecd6050d08d"

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
