import QtQuick
import Quickshell.Hyprland

Item {
	id: root
	property int maximumWidth: 280

	implicitWidth: Math.min(titleLabel.implicitWidth, maximumWidth)
	implicitHeight: titleLabel.implicitHeight

	Text {
		id: titleLabel
		width: root.width
		text: String(Hyprland.activeToplevel?.title || "desktop").toLowerCase()
		color: Theme.moduleValue
		elide: Text.ElideRight
		font {
			family: ShellConfig.typography.monoFamily
			pixelSize: ShellConfig.bar.windowFontSize
		}
	}
}
