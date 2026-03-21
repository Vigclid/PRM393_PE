import { Connection } from "sockjs";
import mongoose from "mongoose";
import {
  addClient,
  removeClient,
  setUserId,
  sendToUser,
  broadcast,
  isRateLimited,
  cleanupRateLimit,
} from "./clientManager";
import { messageService } from "../modules/messages/message.service";
import { chatService } from "../modules/chats/chat.service";

interface SocketMessage {
  type: "INIT" | "CHAT" | "BROADCAST";
  userId?: string;
  from?: string;
  to?: string;
  message?: string;
}

const handleChatMessage = async (data: SocketMessage): Promise<void> => {
  // Validate that from, to, and message are non-null and non-empty
  if (!data.from || !data.to || !data.message) {
    return;
  }

  if (data.from.trim() === "" || data.to.trim() === "" || data.message.trim() === "") {
    return;
  }

  // Validates: Requirements 9.4 - Validate user IDs are valid MongoDB ObjectIds
  if (!mongoose.Types.ObjectId.isValid(data.from)) {
    console.warn(`Invalid user ID in CHAT event - from: ${data.from}`);
    return;
  }

  if (!mongoose.Types.ObjectId.isValid(data.to)) {
    console.warn(`Invalid user ID in CHAT event - to: ${data.to}`);
    return;
  }

  try {
    // Save message to database
    const msgService = new messageService();
    const savedMessage = await msgService.create({
      senderId: data.from,
      receiverId: data.to,
      message: data.message,
      dateSent: new Date(),
      isRead: 0,
    } as any);

    // Emit message to receiver via Socket.IO
    sendToUser(data.to, {
      type: "MESSAGE",
      message: savedMessage,
      timestamp: Date.now(),
    });

    // Update chat status to unread for receiver
    const chatSvc = new chatService();
    const chat = await chatSvc.checkExistChatUser1AndUser2(data.from, data.to);
    if (chat) {
      chat.status = 0;
      await chat.save();
    }
  } catch (error) {
    console.error("Error handling chat message:", error);
  }
};

export const handleSocketConnection = (conn: Connection) => {
  addClient(conn.id, conn);

  conn.on("data", async (message: string) => {
    try {
      // Check rate limit before processing any event
      // Validates: Requirements 8.5
      if (isRateLimited(conn.id)) {
        conn.write(
          JSON.stringify({
            type: "ERROR",
            message: "Rate limit exceeded: Maximum 100 events per minute allowed",
            code: 429,
          })
        );
        return;
      }

      const data: SocketMessage = JSON.parse(message);

      switch (data.type) {
        case "INIT":
          // Validates: Requirements 9.4 - Validate user ID is valid MongoDB ObjectId
          if (data.userId) {
            if (!mongoose.Types.ObjectId.isValid(data.userId)) {
              console.warn(`Invalid user ID in INIT event: ${data.userId}`);
              return;
            }
            setUserId(conn.id, data.userId);
          }
          break;

        case "CHAT":
          await handleChatMessage(data);
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
    cleanupRateLimit(conn.id);
  });
};
