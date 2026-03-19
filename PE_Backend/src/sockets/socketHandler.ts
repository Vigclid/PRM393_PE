import { Connection } from "sockjs";
import { addClient, removeClient, setUserId, sendToUser, broadcast } from "./clientManager";

interface SocketMessage {
  type: "INIT" | "CHAT" | "BROADCAST";
  userId?: string;
  from?: string;
  to?: string;
  message?: string;
}

export const handleSocketConnection = (conn: Connection) => {
  addClient(conn.id, conn);

  conn.on("data", (message: string) => {
    try {
      const data: SocketMessage = JSON.parse(message);

      switch (data.type) {
        case "INIT":
          if (data.userId) {
            setUserId(conn.id, data.userId);
          }
          break;

        case "CHAT":
          if (data.from && data.to && data.message) {
            sendToUser(data.to, {
              type: "CHAT",
              from: data.from,
              message: data.message,
              timestamp: Date.now(),
            });
          }
          break;

        case "BROADCAST":
          if (data.message) {
            broadcast({
              type: "NOTIFY",
              message: data.message,
              timestamp: Date.now(),
            });
          }
          break;

        default:
      }
    } catch (err) {}
  });

  conn.on("close", () => {
    removeClient(conn.id);
  });
};
