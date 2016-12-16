import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import Qt.labs.settings 1.0
import QtQml 2.2
import "qrc:/thymio-vpl2"

ApplicationWindow {
	id: window
	title: qsTr("Thymio Flow")
	visible: true
	width: 960
	height: 600

	Material.primary: Material.theme === Material.Dark ? "#200032" : "#a3d9db"
	Material.accent: Material.theme === Material.Dark ? "#9478aa" : "#59cbc8"

	header: ToolBar {
		RowLayout {
			anchors.fill: parent

			ToolButton {
				contentItem: Image {
					anchors.centerIn: parent
					source: "qrc:/thymio-vpl2/icons/ic_menu_white_24px.svg"
				}
				visible: !vplEditor.blockEditorVisible
				onClicked: drawer.open()
			}

			ToolButton {
				contentItem: Image {
					anchors.centerIn: parent
					source: !!thymio.node ? "qrc:/thymio-vpl2/icons/ic_connection_on_nonAR_white_24px.svg" : "qrc:/thymio-vpl2/icons/ic_connection_off_white_24px.svg"
				}
				visible: !vplEditor.blockEditorVisible
				onClicked: dashelTargetSelector.open()
			}

			CompilationLabel {
				vplEditor: vplEditor
			}

			ToolButton {
				contentItem: Image {
					anchors.centerIn: parent
					anchors.rightMargin: 12
					source: !thymio.playing ? "qrc:/thymio-vpl2/icons/ic_play_arrow_white_24px.svg" : "qrc:/thymio-vpl2/icons/ic_stop_white_24px.svg"
				}
				visible: !vplEditor.blockEditorVisible
				opacity: enabled ? 1.0 : 0.3
				enabled: (vplEditor.compiler.error === "") && (thymio.node !== undefined)
				onClicked: thymio.playing = !thymio.playing
			}
		}
	}

	Editor {
		id: vplEditor
		anchors.fill: parent

		Text {
			text: "developer preview pre-alpha, no feature or design is final"
			anchors.left: parent.left
			anchors.leftMargin: 106
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 10
			color: Material.primaryTextColor
		}
	}

	Connections {
		target: vplEditor.compiler
		onScriptChanged: thymio.playing = false
	}

	ListModel {
		id: menuItems

		ListElement { title: QT_TR_NOOP("load program"); callback: "load"; whiteIcon: "qrc:/thymio-vpl2/icons/ic_open_white_24px.svg"; blackIcon: "qrc:/thymio-vpl2/icons/ic_open_black_24px.svg"; }
		function load() {
			saveProgramDialog.isSave = false;
			saveProgramDialog.visible = true;
		}

		ListElement { title: QT_TR_NOOP("save program"); callback: "save"; whiteIcon: "qrc:/thymio-vpl2/icons/ic_save_white_24px.svg"; blackIcon: "qrc:/thymio-vpl2/icons/ic_save_black_24px.svg"; }
		function save() {
			saveProgramDialog.isSave = true;
			saveProgramDialog.visible = true;
		}

		ListElement { title: QT_TR_NOOP("new program"); callback: "newProgram"; whiteIcon: "qrc:/thymio-vpl2/icons/ic_new_white_24px.svg"; blackIcon: "qrc:/thymio-vpl2/icons/ic_new_black_24px.svg";}
		function newProgram() {
			vplEditor.clearProgram();
			saveProgramDialog.programName = "";
		}

		ListElement { title: QT_TR_NOOP("switch color theme"); callback: "switchColorTheme"; whiteIcon: ""; blackIcon: ""; }
		function switchColorTheme() {
			if (window.Material.theme === Material.Dark) {
				window.Material.theme = Material.Light;
			} else {
				window.Material.theme = Material.Dark;
			}
		}

		ListElement { title: QT_TR_NOOP("switch editor mode"); callback: "switchEditorMode"; whiteIcon: ""; blackIcon: ""; }
		function switchEditorMode() {
			vplEditor.switchMode();
		}

		ListElement { title: qsTr("toggle score bar"); callback: "toggleScoreBar"; whiteIcon: ""; blackIcon: ""; }
		function toggleScoreBar() {
			vplEditor.toggleScoreBar();
		}

		ListElement { title: "dev: show aesl"; callback: "showAeslSource"; whiteIcon: ""; blackIcon: ""; visible: false; }
		function showAeslSource() {
			aeslSourceDialog.visible = true;
		}

		//ListElement { title: QT_TR_NOOP("about"); source: "About.qml" ; icon: "qrc:/thymio-vpl2/icons/ic_info_white_24px.svg" }
	}

	Drawer {
		id: drawer
		edge: Qt.LeftEdge
		position: 0
		width: 300
		height: window.height

		contentItem: Pane {
			ListView {
				id: listView
				currentIndex: -1
				anchors.fill: parent

				model: menuItems

				delegate: ItemDelegate {
					contentItem: Row {
						spacing: 24
						HDPIImage {
							source: Material.theme === Material.Dark ? whiteIcon : blackIcon
							width: 24
							height: 24
							opacity: enabled ? 1.0 : 0.5
						}
						Text {
							text: qsTr(model.title);
							font.pixelSize: 14
							font.weight: Font.Medium
							color: Material.primaryTextColor
							opacity: enabled ? 1.0 : 0.5
							visible: ((model.title.substring(0, 4) !== "dev:") || (Qt.application.arguments.indexOf("--developer") !== -1))
						}
					}
					onClicked: {
						ListView.view.model[callback]();
						drawer.close()
					}
				}
			}
		}
	}

	DashelTargetDialog {
		id: dashelTargetSelector
		aseba: aseba
	}

	LoadSaveDialog {
		id: saveProgramDialog
		vplEditor: vplEditor
	}

	// developer options for debugging
	Popup {
		id: aeslSourceDialog
		x: (parent.width - width) / 2
		y: (parent.height - height) / 2
		width: 0.8 * parent.width
		height: 0.8 * parent.height
		modal: true
		focus: true

		function prettyPrintGeneratedAesl(source) {
			var level = 0;
			var output = "";
			var splitted = source.split("\n");
			for (var i = 0; i < splitted.length; i++) {
				var line = splitted[i].trim();
				if ((line.indexOf("sub ") === 0) || (line.indexOf("onevent ") === 0)) {
					output += "\n" + line + "\n";
					level = 1;
				} else {
					if (line.indexOf("end") === 0) {
						level -= 1;
					}
					for (var j = 0; j < level; j++)
						output += "    ";
					output += line + "\n";
					if (line.indexOf("if ") === 0) {
						level += 1;
					}
				}
			}
			return output;
		}
		Flickable {
			anchors.fill: parent
			clip: true
			Text {
				text: aeslSourceDialog.prettyPrintGeneratedAesl(vplEditor.compiler.script)
				color: Material.primaryTextColor
				font.family: "Monospace"
				// TODO: move this somewhere
			}
			contentWidth: contentItem.childrenRect.width;
			contentHeight: contentItem.childrenRect.height
			ScrollBar.vertical: ScrollBar { }
			ScrollBar.horizontal: ScrollBar { }
		}
	}

	Aseba {
		id: aseba
		onUserMessage: {
			if (type !== 0) {
				return;
			}
			if (vplEditor === undefined) {
				return;
			}
			vplEditor.compiler.execTransition(data[0], data[1]);
		}
	}

	Thymio {
		id: thymio
		property bool playing: false
		events: vplEditor ? vplEditor.compiler.events : {}
		source: playing ? vplEditor.compiler.script : ""
		onNodeChanged: playing = false
		onPlayingChanged: vplEditor.compiler.execReset(playing);
		onErrorChanged: if (error !== "") { vplEditor.compiler.error = error; }
	}
}

