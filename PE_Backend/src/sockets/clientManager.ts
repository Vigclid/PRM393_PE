import { Connection } from "sockjs";

interface ExtendedConnection extends Connection {
  userId?: string;
}

const clients = new Map<string, ExtendedConnection>();

export const addClient = (id: string, conn: ExtendedConnection) => {
  clients.set(id, conn);
};

export const removeClient = (id: string) => {
  clients.delete(id);
};

export const setUserId = (id: string, userId: string) => {
  const conn = clients.get(id);
  if (conn) conn.userId = userId;
};

export const sendToUser = (userId: string, data: object) => {
  for (const [id, conn] of clients) {
    if (conn.userId === userId) {
      try {
        conn.write(JSON.stringify(data));
      } catch (err) {
        console.error("[sendToUser] write error, removing client", id, err);
        clients.delete(id);
      }
    }
  }
};

export const broadcast = (data: object) => {
  for (const [id, conn] of clients) {
    try {
      conn.write(JSON.stringify(data));
    } catch (err) {
      console.error("[broadcast] write error, removing client", id, err);
      clients.delete(id);
    }
  }
};
