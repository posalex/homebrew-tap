cask "claude-usage" do
  version "1.0.0"
  sha256 "f4a69a7712faeeaf5c178f2c74333859ee1899dd7de668386791200fa0a97767"

  url "https://github.com/posalex/ClaudeUsage/releases/download/v#{version}/ClaudeUsage.zip"
  name "Claude Usage"
  desc "macOS menu bar widget showing Claude AI usage statistics"
  homepage "https://github.com/posalex/ClaudeUsage"

  depends_on macos: ">= :ventura"

  app "ClaudeUsage.app"

  zap trash: [
    "~/Library/Preferences/de.fashion-digital.claudeusage.plist",
    "~/Library/Application Support/ClaudeUsage",
  ]
end
