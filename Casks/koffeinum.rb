# A Homebrew **Cask** — the idiomatic choice for distributing a .app.
# Save this as `Casks/koffeinum.rb` in your tap repo (not `Formula/`).
#
# The `sha256` field is rewritten automatically by `make publish-tap` in the
# Koffeinum repo. A fresh clone of the tap will have a PLACEHOLDER value until
# that target has run at least once.
cask "koffeinum" do
  version "1.0.2"
  sha256 "d1343779f3b680abf8089065b5f3a65a0edb529addc16a975d3b1c15df2229e0"

  url "https://github.com/posalex/Koffeinum/releases/download/v1.0.2/Koffeinum.zip"
  name "Koffeinum"
  desc "macOS menu bar app that prevents your Mac from sleeping"
  homepage "https://github.com/posalex/Koffeinum"

  depends_on macos: ">= :monterey"

  app "Koffeinum.app"

  zap trash: [
    "~/Library/Preferences/de.posalex.Koffeinum.plist",
    "~/Library/Application Support/Koffeinum",
  ]

  caveats <<~EOS
    Koffeinum is unsigned (no Apple Developer ID).
    macOS Gatekeeper will block the app on first launch.

    To allow it, run:
      xattr -d com.apple.quarantine /Applications/Koffeinum.app

    Or right-click the app in Finder → Open and confirm the dialog.
  EOS
end
