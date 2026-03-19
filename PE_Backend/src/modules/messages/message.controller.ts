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
}
