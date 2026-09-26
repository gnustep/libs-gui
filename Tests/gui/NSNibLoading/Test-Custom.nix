<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>format</key><string>NIX</string>
  <key>version</key><integer>1</integer>
  <key>objects</key>
  <array>
    <dict>
      <key>$id</key><string>custom-view</string>
      <key>$class</key><string>UnlinkedApplicationView</string>
      <key>$superclass</key><string>NixTestNode</string>
      <key>properties</key>
      <dict>
        <key>name</key><string>Custom placeholder</string>
        <key>applicationState</key><string>preserve me</string>
      </dict>
      <key>connections</key>
      <array>
        <dict>
          <key>kind</key><string>outlet</string>
          <key>source</key><dict><key>$ref</key><string>owner</string></dict>
          <key>destination</key><dict><key>$ref</key><string>custom-view</string></dict>
          <key>label</key><string>node</string>
        </dict>
      </array>
    </dict>
  </array>
  <key>topLevelObjects</key>
  <array><dict><key>$ref</key><string>custom-view</string></dict></array>
</dict>
</plist>
