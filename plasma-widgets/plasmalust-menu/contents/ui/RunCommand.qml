import QtQuick
import org.kde.plasma.plasma5support as P5Support

P5Support.DataSource {
    id: dataSource

    property var callbacks: ({})

    function exec(cmd, callback) {
        if (callback && typeof callback === "function") {
            callbacks[cmd] = callback;
        }
        dataSource.connectSource(cmd);
    }

    engine: "executable"
    connectedSources: []
    onNewData: function (source, data) {
        const stdout = data["stdout"];
        disconnectSource(source);
        if (source in callbacks) {
            const cb = callbacks[source];
            delete callbacks[source];
            if (typeof cb === "function") cb(stdout);
        }
    }
}
