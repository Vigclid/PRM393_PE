"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.broadcast = exports.sendToUser = exports.setUserId = exports.removeClient = exports.addClient = void 0;
const clients = new Map();
const addClient = (id, conn) => {
    clients.set(id, conn);
};
exports.addClient = addClient;
const removeClient = (id) => {
    clients.delete(id);
};
exports.removeClient = removeClient;
const setUserId = (id, userId) => {
    const conn = clients.get(id);
    if (conn)
        conn.userId = userId;
};
exports.setUserId = setUserId;
const sendToUser = (userId, data) => {
    for (const [, conn] of clients) {
        if (conn.userId === userId) {
            conn.write(JSON.stringify(data));
        }
    }
};
exports.sendToUser = sendToUser;
const broadcast = (data) => {
    for (const [, conn] of clients) {
        conn.write(JSON.stringify(data));
    }
};
exports.broadcast = broadcast;
