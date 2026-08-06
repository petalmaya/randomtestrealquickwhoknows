pragma Singleton
import Quickshell
import Quickshell.Io

// TODO
// store and expose other values
// like urgency and what not
// multimonitor support?
Singleton {
  id: root

  // true once we've actually heard from a running mango instance
  property bool active: false
  property string currentWorkspace: "0"

  Process {
    command: ["bash", "-c", "command -v mmsg >/dev/null 2>&1 && exec mmsg watch focusing-client || exit 0"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        let data;
        try {
          data = JSON.parse(line);
        } catch (e) {
          return;
        }

        root.active = true;
        root.currentWorkspace = data.tags[0];
      }
    }
  }

  function setCurrentTag(tagname) {
    Quickshell.execDetached(["mmsg", "dispatch", `view,${tagname}`]);
  }
}
