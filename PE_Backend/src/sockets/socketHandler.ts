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
  console.log(`[handleChatMessage] Starting with data:`, data);
  
  // Validate that from, to, and message are non-null and non-empty
  if (!data.from || !data.to || !data.message) {
    console.warn(`[handleChatMessage] Missing required fields:`, { from: data.from, to: data.to, message: data.message });
    return;
  }

  if (data.from.trim() === "" || data.to.trim() === "" || data.message.trim() === "") {
    console.warn(`[handleChatMessage] Empty fields after trim`);
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
    console.log(`[handleChatMessage] Saving message to database...`);
    // Save message to database
    const msgService = new messageService();
    const savedMessage = await msgService.create({
      senderId: data.from,
      receiverId: data.to,
      message: data.message,
      dateSent: new Date(),
      isRead: 0,
    } as any);
    console.log(`[handleChatMessage] Message saved:`, savedMessage._id);

    // Emit message to receiver via Socket.IO
    console.log(`[handleChatMessage] Sending MESSAGE event to user ${data.to}`);
    sendToUser(data.to, {
      type: "MESSAGE",
      message: savedMessage,
      timestamp: Date.now(),
    });

    // Update chat status to unread for receiver
    console.log(`[handleChatMessage] Updating chat status...`);
    const chatSvc = new chatService();
    const chat = await chatSvc.checkExistChatUser1AndUser2(data.from, data.to);
    if (chat) {
      chat.status = 0;
      await chat.save();
      console.log(`[handleChatMessage] Chat status updated to unread`);
    } else {
      console.warn(`[handleChatMessage] Chat not found between ${data.from} and ${data.to}`);
    }
    
    console.log(`[handleChatMessage] Completed successfully`);
  } catch (error) {
    console.error("[handleChatMessage] Error:", error);
  }
};

export const handleSocketConnection = (conn: Connection) => {
  addClient(conn.id, conn);
  console.log(`[SockJS] New connection: ${conn.id}`);

  conn.on("data", async (message: string) => {
    console.log(`[SockJS] Received data from ${conn.id}:`, message);
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
      console.log(`[SockJS] Parsed data:`, data);

      switch (data.type) {
        case "INIT":
          // Validates: Requirements 9.4 - Validate user ID is valid MongoDB ObjectId
          if (data.userId) {
            if (!mongoose.Types.ObjectId.isValid(data.userId)) {
              console.warn(`Invalid user ID in INIT event: ${data.userId}`);
              return;
            }
            setUserId(conn.id, data.userId);
            console.log(`[SockJS] User ${data.userId} registered to connection ${conn.id}`);
          }
          break;

        case "CHAT":
          console.log(`[SockJS] Processing CHAT event:`, data);
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
          console.log(`[SockJS] Unknown event type: ${data.type}`);
      }
    } catch (err) {
      console.error(`[SockJS] Error processing message:`, err);
    }
  });

  conn.on("error", () => {
    console.log(`[SockJS] Connection error: ${conn.id}`);
    removeClient(conn.id);
  });

  conn.on("close", () => {
    console.log(`[SockJS] Connection closed: ${conn.id}`);
    removeClient(conn.id);
    cleanupRateLimit(conn.id);
  });
};
