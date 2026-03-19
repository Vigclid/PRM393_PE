import { NextFunction, Request, Response } from "express";
import { GenericController } from "../../core/controllers/base.controller";
import { IChat } from "./chat.model";
import { chatService } from "./chat.service";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { sendToUser } from "../../sockets/clientManager";
export class chatController extends GenericController<IChat> {
  private ChatService: chatService;
  constructor(chatService: chatService) {
    super(chatService);
    this.ChatService = chatService;
  }

  getChatSelf = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.ChatService.getChatSelf(id);
      res.status(200).json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  createChatSelf = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      req.body.user1Id = id;
      const exist = (await this.ChatService.checkExistChatUser1AndUser2(
        req.body.user1Id,
        req.body.user2Id
      )) as IChat;

      if (exist) {
        exist.status = 0;
        await exist.save();
        sendToUser(id, { type: "UPDATE_CHAT", chat: exist });
        return res.status(200).json(responseWrapper("success", "Chat already exist"));
      }
      const response = (await this.ChatService.createChatSelf(req.body)) as IChat;
      const chat = await this.ChatService.getChatByIdPopulate(response._id as string);
      sendToUser(id, { type: "NEW_CHAT", chat: chat });
      res.status(201).json(responseWrapper("success", "Created successfully", response));
    } catch (error) {
      next(error);
    }
  };

  markAsReadByUserId = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      await this.ChatService.markAsReadByUserId(id);
      res.status(200).json(responseWrapper("success", "Mark as read successfully"));
    } catch (error) {
      next(error);
    }
  };

  getChatByMeAndOther = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.ChatService.checkExistChatUser1AndUser2(id, req.params.id);
      res.status(200).json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };
}
