import QtQuick

Item {
	id: root

	required property string label
	required property real value

	readonly property bool hovered: summaryHover.hovered

	implicitWidth: ShellConfig.bar.controlSummaryWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize

	Rectangle {
		anchors.fill: parent
		radius: 0
		color: root.hovered ? Theme.panelRaised : "transparent"
		border.width: root.hovered ? ShellConfig.bar.contentBorderWidth : 0
		border.color: Theme.frameBorder

		Behavior on color {
			ColorAnimation { duration: ShellConfig.bar.mediaAnimationMs }
		}
	}

	Row {
		id: summaryRow

		anchors.centerIn: parent
		spacing: ShellConfig.bar.controlSummarySpacing

		Text {
			width: ShellConfig.bar.controlSummaryLabelWidth
			height: ShellConfig.bar.mediaButtonSize
			text: root.label.toLowerCase() + ":"
			color: Theme.moduleLabel
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				styleName: ShellConfig.typography.fineStyle
				pixelSize: ShellConfig.bar.valueFontSize
				weight: ShellConfig.bar.labelFontWeight
			}
		}

		Text {
			width: ShellConfig.bar.controlSummaryValueWidth
			height: ShellConfig.bar.mediaButtonSize
			text: `${Math.round(root.value * 100)}%`
			color: Theme.moduleValue
			horizontalAlignment: Text.AlignRight
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.valueFontSize
			}
		}
	}

	Item {
		anchors {
			fill: parent
			topMargin: -ShellConfig.bar.popupTriggerTopExtension
		}

		HoverHandler {
			id: summaryHover
		}
	}
}
