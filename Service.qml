pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons

Scope {
  id: root
  property var shell: null
  property bool ready: false
  property bool failed: false
  property string dataPath: Quickshell.env("HOME") + "/.local/state/omarchy/desktop-notes.json"
  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
  ListModel { id: entries }

  function load(raw) {
    try {
      const data = JSON.parse(raw)
      if (!Array.isArray(data) || data.length > 1000) throw new Error("Invalid data")
      for (let i = 0; i < data.length; ++i) {
        const item = data[i]
        if (!item || (item.kind !== "note" && item.kind !== "task") || typeof item.text !== "string" || item.text.length > 20000 || typeof item.done !== "boolean") throw new Error("Invalid entry")
      }
      entries.clear()
      for (let i = 0; i < data.length; ++i) entries.append(data[i])
      ready = true
    } catch (error) { failed = true; console.warn("Desktop Notes: invalid data", error) }
  }
  function save() {
    if (!ready) return
    let data = []
    for (let i = 0; i < entries.count; ++i) {
      const item = entries.get(i)
      data.push({kind: item.kind, text: item.text, done: item.done})
    }
    file.setText(JSON.stringify(data, null, 2) + "\n")
  }
  function add(kind) {
    if (!ready) return
    entries.append({kind: kind, text: "", done: false})
    save()
    Qt.callLater(function() { list.positionViewAtEnd() })
  }
  Timer { id: saveTimer; interval: 400; onTriggered: root.save() }
  FileView {
    id: file
    path: root.dataPath
    atomicWrites: true
    onLoaded: root.load(text())
    onLoadFailed: { root.failed = true; console.warn("Desktop Notes: cannot read data file") }
    onSaveFailed: error => { root.failed = true; console.warn("Desktop Notes: cannot save data", error) }
  }
  Variants {
    model: Quickshell.screens.length ? [Quickshell.screens[0]] : []
    PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      implicitWidth: Math.min(370, Math.max(260, modelData.width - 32))
      implicitHeight: Math.min(520, Math.max(240, modelData.height - 100))
      anchors.top: true
      anchors.right: true
      margins.top: 70
      margins.right: 20
      exclusionMode: ExclusionMode.Ignore
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      WlrLayershell.namespace: "local-desktop-notes"
      Rectangle {
        anchors.fill: parent
        radius: 16
        color: Commons.Color.popups.background
        border.color: Commons.Color.popups.border
        border.width: 1
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 16
          spacing: 10
          Text {
            text: strings.t("title")
            textFormat: Text.PlainText
            font.pixelSize: 19
            font.bold: true
            color: Commons.Color.popups.text
          }
          RowLayout {
            spacing: 8
            Button { text: strings.t("note"); enabled: root.ready && !root.failed; onClicked: root.add("note") }
            Button { text: strings.t("task"); enabled: root.ready && !root.failed; onClicked: root.add("task") }
            Item { Layout.fillWidth: true }
          }
          Text {
            visible: root.failed
            text: strings.t("error")
            textFormat: Text.PlainText
            color: Commons.Color.urgent
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Text {
              anchors.centerIn: parent
              visible: entries.count === 0 && root.ready
              text: strings.t("empty")
              textFormat: Text.PlainText
              color: Commons.Color.muted
            }
            ListView {
              id: list
              anchors.fill: parent
              clip: true
              spacing: 8
              model: entries
              ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
              delegate: Rectangle {
                id: row
                required property int index
                required property string kind
                required property string text
                required property bool done
                width: list.width
                height: Math.max(48, editor.implicitHeight + 12)
                radius: 9
                color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.07)
                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 6
                  anchors.rightMargin: 6
                  CheckBox {
                    visible: row.kind === "task"
                    enabled: root.ready && !root.failed
                    checked: row.done
                    onToggled: { entries.setProperty(row.index, "done", checked); root.save() }
                  }
                  TextArea {
                    id: editor
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: row.text
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    color: Commons.Color.popups.text
                    opacity: row.done ? 0.55 : 1
                    font.strikeout: row.done
                    placeholderText: row.kind === "task" ? strings.t("placeholderTask") : strings.t("placeholderNote")
                    readOnly: !root.ready || root.failed
                    onTextChanged: {
                      if (root.ready && !root.failed && text !== row.text) {
                        entries.setProperty(row.index, "text", text.slice(0, 20000))
                        saveTimer.restart()
                      }
                    }
                  }
                  Button {
                    text: "×"
                    enabled: root.ready && !root.failed
                    Accessible.name: strings.t("remove")
                    onClicked: { saveTimer.stop(); entries.remove(row.index); root.save() }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
