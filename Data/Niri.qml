pragma Singleton
import Quickshell
import Quickshell.Io

// Talks to niri over its IPC event-stream (`niri msg -j event-stream`)
// to keep track of the focused workspace, and issues `niri msg action ...`
// commands to change focus. Replaces the old MangoWC (mmsg) integration.
//
// niri workspaces live per-output, so everything here is keyed by output
// name (e.g. "eDP-1") to support one bar per monitor, each showing (and
// controlling) only its own monitor's workspaces.
//
// TODO
// store and expose other values, like urgency
Singleton {
  id: root

  // true once we've actually heard from a running niri instance
  property bool active: false
  // idx (1-based) of the globally focused workspace, kept for single
  // monitor / back-compat callers that don't care which output
  property int currentWorkspace: 1
  // name of the output whose workspace is currently focused - this is
  // niri's notion of "the monitor you're on", useful for anything that
  // needs to default to "wherever the user currently is" (e.g. the app
  // launcher when triggered by a global keybind/IPC with no output arg)
  property string focusedOutput: ""
  // output name -> idx of that output's currently visible workspace
  property var currentWorkspaceByOutput: ({})
  // id -> workspace object, as last reported by niri
  property var workspaces: ({})

  function _applyWorkspace(w) {
    if (!w || !w.output)
      return;

    const updated = Object.assign({}, root.currentWorkspaceByOutput);
    updated[w.output] = w.idx;
    root.currentWorkspaceByOutput = updated;

    if (w.is_focused) {
      root.currentWorkspace = w.idx;
      root.focusedOutput = w.output;
    }
  }

  // workspace idx currently shown on the given output, falling back to
  // the globally focused idx if we don't have per-output data yet
  function workspaceFor(outputName) {
    if (outputName && root.currentWorkspaceByOutput[outputName] !== undefined) {
      return root.currentWorkspaceByOutput[outputName];
    }
    return root.currentWorkspace;
  }

  function _escape(str) {
    return `'${String(str).replace(/'/g, `'\\''`)}'`;
  }

  // focuses the given monitor first (if provided) so the workspace index
  // is resolved relative to *that* output, then focuses the workspace.
  // niri resolves "focus-workspace <idx>" relative to whichever monitor
  // is currently focused, so a plain single dispatch can't target a
  // non-focused monitor reliably.
  function setCurrentTag(idx, outputName) {
    if (outputName) {
      Quickshell.execDetached(["bash", "-c", `niri msg action focus-monitor ${root._escape(outputName)} && niri msg action focus-workspace ${idx}`]);
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", `${idx}`]);
    }
  }

  function focusNext(outputName) {
    if (outputName) {
      Quickshell.execDetached(["bash", "-c", `niri msg action focus-monitor ${root._escape(outputName)} && niri msg action focus-workspace-down`]);
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
    }
  }

  function focusPrev(outputName) {
    if (outputName) {
      Quickshell.execDetached(["bash", "-c", `niri msg action focus-monitor ${root._escape(outputName)} && niri msg action focus-workspace-up`]);
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
    }
  }

  Process {
    command: ["niri", "msg", "-j", "event-stream"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        if (!line || line.length === 0)
          return;

        let event;
        try {
          event = JSON.parse(line);
        } catch (e) {
          return;
        }

        root.active = true;

        if (event.WorkspacesChanged) {
          const ws = {};
          for (const w of event.WorkspacesChanged.workspaces) {
            ws[w.id] = w;
            if (w.is_active) {
              root._applyWorkspace(w);
            }
          }
          root.workspaces = ws;
        } else if (event.WorkspaceActivated) {
          const activated = event.WorkspaceActivated;
          const w = root.workspaces[activated.id];
          if (w) {
            w.is_active = true;
            // niri only tells us here whether this activation also
            // moved global focus (switching workspace on a
            // non-focused monitor activates it without focusing it) -
            // is_focused has to be derived from that, it isn't implied
            // by is_active
            w.is_focused = !!activated.focused;
            root._applyWorkspace(w);
          }
        }
      }
    }
  }
}
