cask "claude-usage" do
  version "1.1.3"
  sha256 "dc408d2955e919a8ce0115e6f6192a447ad19c90798f2cbee8bbcd6e1eda3d50"

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
