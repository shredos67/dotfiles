pragma Singleton

import QtQuick

QtObject {
	id: root

	property string activePanel: ""
	property string pinnedPopover: ""

	signal panelClaimed(string name)
	signal panelCloseRequested(string name)
	signal popoverChanged(string name)

	function claimPanel(name: string): void {
		if (!name.length)
			return

		activePanel = name
		panelClaimed(name)
	}

	function releasePanel(name: string): void {
		if (activePanel === name)
			activePanel = ""
	}

	function requestClose(): void {
		if (activePanel.length)
			panelCloseRequested(activePanel)
	}

	function pinPopover(name: string): void {
		pinnedPopover = pinnedPopover === name ? "" : name
		popoverChanged(pinnedPopover)
	}

	function closePopover(): void {
		if (!pinnedPopover.length)
			return

		pinnedPopover = ""
		popoverChanged("")
	}
}
