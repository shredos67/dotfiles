import QtQuick

Item {
	implicitWidth: ShellConfig.bar.separatorWidth
	implicitHeight: ShellConfig.bar.separatorDiamondSize

	Rectangle {
		anchors.centerIn: parent
		width: parent.width
		height: ShellConfig.bar.hairlineThickness
		color: Theme.separator
	}

	Rectangle {
		anchors.centerIn: parent
		width: ShellConfig.bar.separatorDiamondSize
		height: width
		rotation: 45
		color: Theme.panel
		border.width: ShellConfig.bar.hairlineThickness
		border.color: Theme.frameBorderSoft
	}
}
