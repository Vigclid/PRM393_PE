import { NextFunction, Request, Response } from "express";
import { GenericController } from "../../core/controllers/base.controller";
import { IMessage } from "./message.model";
import { messageService } from "./message.service";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { sendToUser } from "../../sockets/clientManager";
import { chatService } from "../chats/chat.service";
export class messageController extends GenericController<IMessage> {
  private MessageService: messageService;

  constructor(messageService: messageService) {
    super(messageService);
    this.MessageService = messageService;
  }
  getMessagesSelf = async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(_req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.MessageService.getMessagesSelf(id);
      res.status(200).json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  createMessageByMe = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      req.body.senderId = id;
      const chat = await new chatService().checkExistChatUser1AndUser2(
        req.body.senderId,
        req.body.receiverId
      );
      if (chat) {
        chat.status = 0;
        await chat.save();
      }
      const message = await this.MessageService.create(req.body);
      sendToUser(req.body.receiverId, { type: "MESSAGE", message });
      res.status(200).json(responseWrapper("success", "Fetched successfully", message));
    } catch (error) {
      next(error);
    }
  };

  getSelftChatWithUserId = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.MessageService.getSelftChatWithUserId(id, req.params.userId);
      res.status(200).json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  getMessagesByChatId = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const { chatId } = req.params;
      const limit = parseInt(req.query.limit as string) || 50;
      const offset = parseInt(req.query.offset as string) || 0;

      // Fetch the chat to get user1Id and user2Id
      const chat = await new chatService().getById(chatId);
      if (!chat) {
        return res.status(404).json(responseWrapper("error", "Chat not found", null));
      }

      // Verify the authenticated user is part of this chat
      if (chat.user1Id !== id && chat.user2Id !== id) {
        return res.status(403).json(responseWrapper("error", "Unauthorized access to chat", null));
      }

      const response = await this.MessageService.getMessagesByChatId(
        chat.user1Id,
        chat.user2Id,
        limit,
        offset
      );
      res.status(200).json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  markAsRead = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const { messageId } = req.params;

      // Fetch the message
      const message = await this.MessageService.getById(messageId);
      if (!message) {
        return res.status(404).json(responseWrapper("error", "Message not found", null));
      }

      // Verify the authenticated user is the receiver
      if (message.receiverId !== id) {
        return res.status(403).json(responseWrapper("error", "Unauthorized", null));
      }

      // Update message.isRead to 1
      message.isRead = 1;
      await message.save();

      // Check if all messages in the chat are read
      const chatSvc = new chatService();
      const chat = await chatSvc.checkExistChatUser1AndUser2(message.senderId, message.receiverId);
      
      if (chat) {
        // Get all messages in this chat
        const allMessages = await this.MessageService.getSelftChatWithUserId(
          chat.user1Id,
          chat.user2Id
        );

        // Check if all messages are read
        const allRead = allMessages.every((msg: any) => msg.isRead === 1);

        if (allRead) {
          // Update chat status to 1
          chat.status = 1;
          await chat.save();

          // Emit UPDATE_CHAT event to both users
          const populatedChat = await chatSvc.getChatByIdPopulate(chat.id);
          sendToUser(chat.user1Id, {
            type: "UPDATE_CHAT",
            chat: populatedChat,
          });
          sendToUser(chat.user2Id, {
            type: "UPDATE_CHAT",
            chat: populatedChat,
          });
        }
      }

      res.status(200).json(responseWrapper("success", "Message marked as read", message));
    } catch (error) {
      next(error);
    }
  };

  getUnreadCount = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };

      const count = await this.MessageService.getUnreadCount(id);

      res.status(200).json(responseWrapper("success", "Unread count fetched successfully", { count }));
    } catch (error) {
      next(error);
    }
  };
}
