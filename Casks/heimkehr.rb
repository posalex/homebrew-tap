cask "heimkehr" do
  version "1.0.0"
  sha256 "f3ce2c7c36da37fe01e13f6ed9a3eb0383699e1c5b9893ecb51540e4f25f409a"

  url "https://github.com/posalex/Heimkehr/releases/download/v#{version}/Heimkehr-#{version}.zip",
      verified: "github.com/posalex/Heimkehr/"
  name "Heimkehr"
  desc "Menu-bar app that moves every window to a chosen display"
  homepage "https://github.com/posalex/Heimkehr"

  depends_on macos: ">= :ventura"

  app "Heimkehr.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Heimkehr.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/de.local.heimkehr.plist",
    "~/Library/Saved Application State/de.local.heimkehr.savedState",
  ]

  caveats <<~EOS
    Heimkehr needs Accessibility permission to move windows of other apps.

    After the first launch, open:
      System Settings → Privacy & Security → Accessibility
    and enable the switch next to "Heimkehr".

    If Launch-at-Login shows as disabled in System Settings,
    toggle it once from the Heimkehr menu to register.
  EOS
end
