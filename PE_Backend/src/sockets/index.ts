import sockjs from "sockjs";
import { Server } from "http";
import { handleSocketConnection } from "./socketHandler";

export const initSocketServer = (server: Server) => {
  const sockServer = sockjs.createServer({
    prefix: "/ws",
    log: (severity, message) => {
      if (severity === "error") console.error(message);
    },
  });

  sockServer.on("connection", handleSocketConnection);

  sockServer.installHandlers(server, { prefix: "/ws" });
};
