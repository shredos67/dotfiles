pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
	id: root

	required property QsMenuEntry modelData
	property bool hovered: pointer.containsMouse
	signal selected(entry: QsMenuEntry)

	readonly property bool isCheck:
		modelData.buttonType === QsMenuButtonType.CheckBox
	readonly property bool isRadio:
		modelData.buttonType === QsMenuButtonType.RadioButton
	readonly property bool isChecked: modelData.checkState === Qt.Checked
		|| modelData.checkState === Qt.PartiallyChecked

	implicitWidth: 300
	implicitHeight: modelData.isSeparator ? 11 : 43

	Rectangle {
		anchors {
			left: parent.left
			right: parent.right
			verticalCenter: parent.verticalCenter
			leftMargin: 10
			rightMargin: 10
		}
		height: 1
		visible: root.modelData.isSeparator
		color: Theme.frameBorderFaint
	}

	Rectangle {
		anchors.fill: parent
		visible: !root.modelData.isSeparator
		radius: ShellConfig.visuals.controlRadius
		color: root.hovered && root.modelData.enabled
			? Theme.panelHighlight : "transparent"
		border.width: root.hovered && root.modelData.enabled ? 1 : 0
		border.color: Theme.frameBorderSoft

		Behavior on color {
			ColorAnimation {
				duration: FloralSettings.duration(
					ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}
	}

	Item {
		id: stateMark

		anchors {
			left: parent.left
			leftMargin: 12
			verticalCenter: parent.verticalCenter
		}
		width: 16
		height: 16
		visible: !root.modelData.isSeparator
			&& (root.isCheck || root.isRadio)

		Rectangle {
			anchors.centerIn: parent
			width: 13
			height: 13
			radius: root.isRadio ? width / 2 : 4
			color: root.isChecked
				? Theme.accentWashStrong : "transparent"
			border.width: 1
			border.color: root.isChecked
				? Theme.accentPrimary : Theme.frameBorderSoft
		}

		Rectangle {
			anchors.centerIn: parent
			width: root.isRadio ? 5 : 8
			height: root.isRadio ? 5 : 2
			radius: root.isRadio ? width / 2 : 1
			rotation: root.isRadio ? 0 : -45
			visible: root.isChecked
			color: Theme.moduleValue
		}

		Rectangle {
			x: 3
			y: 8
			width: 5
			height: 2
			radius: 1
			rotation: 45
			visible: root.isCheck && root.isChecked
			color: Theme.moduleValue
		}
	}

	IconImage {
		id: entryIcon

		anchors {
			left: parent.left
			leftMargin: 11
			verticalCenter: parent.verticalCenter
		}
		implicitSize: 18
		asynchronous: true
		visible: !root.modelData.isSeparator
			&& !stateMark.visible && String(source).length > 0
		source: root.modelData.icon
	}

	Text {
		anchors {
			left: parent.left
			leftMargin: stateMark.visible || entryIcon.visible ? 39 : 13
			right: nestedMark.visible ? nestedMark.left : parent.right
			rightMargin: nestedMark.visible ? 12 : 13
			verticalCenter: parent.verticalCenter
		}
		visible: !root.modelData.isSeparator
		text: root.modelData.text
		color: root.modelData.enabled
			? Theme.moduleValue : Theme.textMuted
		elide: Text.ElideRight
		renderType: Text.NativeRendering
		font {
			family: ShellConfig.typography.monoFamily
			styleName: ShellConfig.typography.fineStyle
			pixelSize: ShellConfig.scaled(12)
			weight: root.hovered ? Font.DemiBold : Font.Normal
		}
	}

	Item {
		id: nestedMark

		anchors {
			right: parent.right
			rightMargin: 13
			verticalCenter: parent.verticalCenter
		}
		width: 12
		height: 16
		visible: !root.modelData.isSeparator
			&& root.modelData.hasChildren

		Rectangle {
			x: 3
			y: 4
			width: 7
			height: 1
			radius: 1
			rotation: 45
			color: root.modelData.enabled
				? Theme.moduleLabel : Theme.textMuted
		}

		Rectangle {
			x: 3
			y: 9
			width: 7
			height: 1
			radius: 1
			rotation: -45
			color: root.modelData.enabled
				? Theme.moduleLabel : Theme.textMuted
		}
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		enabled: !root.modelData.isSeparator && root.modelData.enabled
		hoverEnabled: true
		cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: root.selected(root.modelData)
	}
}
