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
  for (const [, conn] of clients) {
    if (conn.userId === userId) {
      conn.write(JSON.stringify(data));
    }
  }
};

export const broadcast = (data: object) => {
  for (const [, conn] of clients) {
    conn.write(JSON.stringify(data));
  }
};
