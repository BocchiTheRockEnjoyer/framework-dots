// Adds a top bar, a dock and two desktop widgets. Existing panels are left alone.
var t = new Panel("org.kde.panel"); t.location = "top"; t.height = 30; t.floating = false; t.opacity = "opaque";
var k = t.addWidget("org.kde.plasma.kickoff"); k.currentConfigGroup = ["General"]; k.writeConfig("icon", "framework-logo-dots14-symbolic"); k.reloadConfig();
["local.dotdesktops", "local.dotkeys", "local.dotsysmon", "local.dotplaying", "org.kde.plasma.panelspacer", "local.dotclock", "org.kde.plasma.panelspacer", "local.dottimer", "org.kde.plasma.systemtray", "local.claudeusage", "local.dotbatterypercent", "org.kde.plasma.showdesktop"].forEach(function(w) { t.addWidget(w); });
var d = new Panel("org.kde.panel"); d.location = "bottom"; d.height = 60; d.lengthMode = "fit"; d.alignment = "center"; d.floating = true; d.hiding = "dodgewindows"; d.opacity = "translucent";
d.addWidget("org.kde.plasma.icontasks"); d.addWidget("org.kde.plasma.marginsseparator");
var g = d.addWidget("org.kde.plasma.kickerdash"); g.currentConfigGroup = ["General"]; g.writeConfig("useCustomButtonImage", true); g.writeConfig("customButtonImage", "view-app-grid-symbolic"); g.reloadConfig();
var desk = desktops()[0]; desk.addWidget("local.dotboard", 60, 60, 416, 208); desk.addWidget("local.dotmedia", 60, 300, 464, 208);
