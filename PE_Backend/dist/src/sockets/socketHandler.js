"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleSocketConnection = void 0;
const clientManager_1 = require("./clientManager");
const handleSocketConnection = (conn) => {
    (0, clientManager_1.addClient)(conn.id, conn);
    conn.on("data", (message) => {
        try {
            const data = JSON.parse(message);
            switch (data.type) {
                case "INIT":
                    if (data.userId) {
                        (0, clientManager_1.setUserId)(conn.id, data.userId);
                    }
                    break;
                case "CHAT":
                    if (data.from && data.to && data.message) {
                        (0, clientManager_1.sendToUser)(data.to, {
                            type: "CHAT",
                            from: data.from,
                            message: data.message,
                            timestamp: Date.now(),
                        });
                    }
                    break;
                case "BROADCAST":
                    if (data.message) {
                        (0, clientManager_1.broadcast)({
                            type: "NOTIFY",
                            message: data.message,
                            timestamp: Date.now(),
                        });
                    }
                    break;
                default:
            }
        }
        catch (err) { }
    });
    conn.on("close", () => {
        (0, clientManager_1.removeClient)(conn.id);
    });
};
exports.handleSocketConnection = handleSocketConnection;
