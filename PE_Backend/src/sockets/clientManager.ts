import { Connection } from "sockjs";

interface ExtendedConnection extends Connection {
  userId?: string;
  eventCount?: number;
  lastResetTime?: number;
}

interface RateLimitInfo {
  count: number;
  resetTime: number;
}

const clients = new Map<string, ExtendedConnection>();
const rateLimitMap = new Map<string, RateLimitInfo>();

// Rate limit: 100 events per minute per connection
const RATE_LIMIT_MAX_EVENTS = 100;
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute

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

/**
 * Check if a connection has exceeded the rate limit
 * Validates: Requirements 8.5
 * @param connId - Connection ID
 * @returns true if rate limit exceeded, false otherwise
 */
export const isRateLimited = (connId: string): boolean => {
  const now = Date.now();
  const rateLimitInfo = rateLimitMap.get(connId);

  if (!rateLimitInfo) {
    // First event from this connection
    rateLimitMap.set(connId, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW_MS,
    });
    return false;
  }

  // Check if window has expired
  if (now >= rateLimitInfo.resetTime) {
    // Reset the counter
    rateLimitMap.set(connId, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW_MS,
    });
    return false;
  }

  // Increment counter
  rateLimitInfo.count++;

  // Check if limit exceeded
  if (rateLimitInfo.count > RATE_LIMIT_MAX_EVENTS) {
    return true;
  }

  return false;
};

/**
 * Clean up rate limit info when connection is removed
 * @param connId - Connection ID
 */
export const cleanupRateLimit = (connId: string): void => {
  rateLimitMap.delete(connId);
};
