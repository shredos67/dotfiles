import QtQuick
import QtQuick.Controls as Controls
import qs.components

Item {
	id: root

	required property bool open
	required property date currentDate

	signal closeRequested

	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: ShellConfig.bar.calendarPopupHeight
		+ ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0
	property real offsetScale: open ? 0 : 1
	property int viewedYear: currentDate.getFullYear()
	property int viewedMonth: currentDate.getMonth()

	function resetToday(): void {
		viewedYear = currentDate.getFullYear()
		viewedMonth = currentDate.getMonth()
	}

	function shiftMonth(delta: int): void {
		const next = new Date(viewedYear, viewedMonth + delta, 1)
		viewedYear = next.getFullYear()
		viewedMonth = next.getMonth()
	}

	function sameDay(left: date, right: date): bool {
		return left.getFullYear() === right.getFullYear()
			&& left.getMonth() === right.getMonth()
			&& left.getDate() === right.getDate()
	}

	onOpenChanged: {
		if (open) {
			resetToday()
			forceActiveFocus()
		}
	}

	visible: open || offsetScale < 1
	width: ShellConfig.bar.calendarPopupWidth
	height: visualTop + panelHeight + animationOverflow
	focus: open

	Keys.onEscapePressed: root.closeRequested()
	Keys.onLeftPressed: root.shiftMonth(-1)
	Keys.onRightPressed: root.shiftMonth(1)
	Keys.onPressed: event => {
		if (event.key === Qt.Key_Home) {
			root.resetToday()
			event.accepted = true
		}
	}

	Behavior on offsetScale {
		NumberAnimation {
			duration: ShellConfig.bar.calendarAnimationMs
			easing.type: Easing.OutCubic
		}
	}

	PopupBridge {
		active: root.visible
		width: root.width
	}

	Item {
		x: 0
		y: root.visualTop
		width: root.width
		height: root.panelHeight + root.animationOverflow
		clip: true

		Item {
			x: 0
			y: root.slideOffset
			width: root.width
			height: root.panelHeight

			PopupChrome { anchors.fill: parent }

			Item {
				id: content

				x: ShellConfig.bar.calendarPopupPadding
				y: ShellConfig.bar.calendarPopupPadding
				width: parent.width
					- ShellConfig.bar.calendarPopupPadding * 2
				height: parent.height
					- ShellConfig.bar.calendarPopupPadding * 2

				Item {
					id: header

					width: parent.width
					height: ShellConfig.bar.calendarHeaderHeight

					RenderedButton {
						id: previousButton

						anchors {
							left: parent.left
							verticalCenter: parent.verticalCenter
						}
						kind: -1
						onActivated: root.shiftMonth(-1)
					}

					Rectangle {
						id: monthButton

						anchors {
							left: previousButton.right
							right: nextButton.left
							leftMargin: ShellConfig.scaled(6)
							rightMargin: ShellConfig.scaled(6)
							verticalCenter: parent.verticalCenter
						}
						height: ShellConfig.bar.calendarNavButtonSize
						radius: ShellConfig.visuals.controlRadius
						color: monthPointer.containsMouse
							? Theme.panelRaised : "transparent"
						border.width: monthPointer.containsMouse
							? ShellConfig.bar.hairlineThickness : 0
						border.color: Theme.frameBorderFaint

						Behavior on color {
							ColorAnimation {
								duration: ShellConfig.visuals.motionFast
							}
						}

						Text {
							anchors.centerIn: parent
							text: Qt.formatDate(new Date(root.viewedYear,
								root.viewedMonth, 1), "MMMM yyyy").toLowerCase()
							color: Theme.moduleLabel
							font {
								family: ShellConfig.typography.monoFamily
								styleName: ShellConfig.typography.fineStyle
								pixelSize: ShellConfig.bar.calendarMonthTitleSize
								weight: Font.DemiBold
								letterSpacing: ShellConfig.bar.labelLetterSpacing
							}
						}

						MouseArea {
							id: monthPointer

							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: root.resetToday()
						}
					}

					RenderedButton {
						id: nextButton

						anchors {
							right: closeButton.left
							rightMargin: ShellConfig.scaled(5)
							verticalCenter: parent.verticalCenter
						}
						kind: 1
						onActivated: root.shiftMonth(1)
					}

					RenderedButton {
						id: closeButton

						anchors {
							right: parent.right
							verticalCenter: parent.verticalCenter
						}
						kind: 0
						onActivated: root.closeRequested()
					}
				}

				Rectangle {
					id: headerDivider

					x: 0
					y: header.y + header.height + ShellConfig.scaled(3)
					width: parent.width
					height: ShellConfig.bar.hairlineThickness
					color: Theme.frameBorderFaint

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

				Controls.DayOfWeekRow {
					id: weekDays

					x: 0
					y: headerDivider.y + headerDivider.height
						+ ShellConfig.scaled(3)
					width: parent.width
					height: ShellConfig.bar.calendarWeekdayHeight
					locale: monthGrid.locale

					delegate: Text {
						required property var model

						text: model.shortName.toLowerCase()
						color: model.day === 0 || model.day === 6
							? Theme.accentSecondary : Theme.textMuted
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						font {
							family: ShellConfig.typography.monoFamily
							pixelSize: ShellConfig.bar.calendarWeekdaySize
							weight: Font.DemiBold
						}
					}
				}

				Controls.MonthGrid {
					id: monthGrid

					x: 0
					y: weekDays.y + weekDays.height + ShellConfig.scaled(2)
					width: parent.width
					height: ShellConfig.bar.calendarDayCellHeight * 6
					month: root.viewedMonth
					year: root.viewedYear
					locale: Qt.locale()
					spacing: 0

					delegate: Item {
						id: dayCell

						required property var model

						implicitWidth: monthGrid.width / 7
						implicitHeight: ShellConfig.bar.calendarDayCellHeight

						Rectangle {
							anchors.centerIn: parent
							width: Math.min(parent.width - ShellConfig.scaled(5),
								parent.height - ShellConfig.scaled(2))
							height: width
							radius: ShellConfig.visuals.controlRadius
							color: dayCell.model.today
								? Theme.accentWashStrong : "transparent"
							border.width: dayCell.model.today
								? ShellConfig.bar.hairlineThickness : 0
							border.color: Theme.frameBorder
						}

						Text {
							anchors.centerIn: parent
							text: dayCell.model.day
							color: {
								if (dayCell.model.today)
									return Theme.moduleLabel
								const weekDay = dayCell.model.date.getDay()
								return weekDay === 0 || weekDay === 6
									? Theme.accentSecondary : Theme.moduleValue
							}
							opacity: dayCell.model.month === monthGrid.month
								? 1 : 0.30
							font {
								family: ShellConfig.typography.monoFamily
								pixelSize: ShellConfig.bar.calendarDaySize
								weight: dayCell.model.today
									? Font.Bold : Font.Medium
							}
						}
					}
				}
			}
		}
	}

	component RenderedButton: Item {
		id: control

		property int kind: 0
		signal activated

		implicitWidth: ShellConfig.bar.calendarNavButtonSize
		implicitHeight: ShellConfig.bar.calendarNavButtonSize
		scale: controlPointer.pressed ? 0.90
			: controlPointer.containsMouse ? 1.04 : 1

		Behavior on scale {
			NumberAnimation {
				duration: ShellConfig.visuals.motionFast
				easing.type: Easing.OutCubic
			}
		}

		Rectangle {
			anchors.fill: parent
			radius: ShellConfig.visuals.controlRadius
			color: controlPointer.containsMouse
				? Theme.panelHighlight : Theme.panelRaised
			border.width: ShellConfig.bar.hairlineThickness
			border.color: controlPointer.containsMouse
				? Theme.frameBorder : Theme.frameBorderFaint

			Behavior on color {
				ColorAnimation { duration: ShellConfig.visuals.motionFast }
			}
		}

		Canvas {
			id: controlMark

			anchors.centerIn: parent
			width: ShellConfig.scaled(11)
			height: width
			property color markColor: Theme.moduleLabel

			onMarkColorChanged: requestPaint()
			onPaint: {
				const context = getContext("2d")
				context.reset()
				context.strokeStyle = markColor
				context.lineWidth = Math.max(1.5, ShellConfig.uiScale * 1.35)
				context.lineCap = "round"
				context.lineJoin = "round"
				context.beginPath()
				if (control.kind === 0) {
					context.moveTo(2.5, 2.5)
					context.lineTo(width - 2.5, height - 2.5)
					context.moveTo(width - 2.5, 2.5)
					context.lineTo(2.5, height - 2.5)
				} else if (control.kind < 0) {
					context.moveTo(width * 0.67, 2)
					context.lineTo(width * 0.34, height / 2)
					context.lineTo(width * 0.67, height - 2)
				} else {
					context.moveTo(width * 0.33, 2)
					context.lineTo(width * 0.66, height / 2)
					context.lineTo(width * 0.33, height - 2)
				}
				context.stroke()
			}
		}

		MouseArea {
			id: controlPointer

			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: control.activated()
		}
	}
}
