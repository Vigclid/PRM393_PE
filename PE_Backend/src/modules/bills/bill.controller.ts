import { GenericController } from "../../core/controllers/base.controller";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { IBill } from "./bill.model";
import { billService } from "./bill.service";
import cartModel, { ICart } from "../cart/cart.model";
import { cartService } from "../cart/cart.service";
import { chatService } from "../chats/chat.service";
import { sendToUser } from "../../sockets/clientManager";
import { messageService } from "../messages/message.service";
import { IProduct } from "../products/product.model";
export class billController extends GenericController<IBill> {
  private BillService: billService;
  constructor(billService: billService) {
    super(billService);
    this.BillService = billService;
  }

  checkout = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const cart = await cartModel.findOne({ userId: id });
      await this.autoSentMessage(req, res, next);
      const response = await this.BillService.checkout(id, cart as ICart);
      await cartModel.findOneAndUpdate({ userId: id }, { items: [], totalPrice: 0 });
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  getRevenueStatistics = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { type } = req.query;
      const response = await this.BillService.getRevenueStatistics(type as any);
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  autoSentMessage = async (req: Request, _res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const cart = await new cartService().getMyCartPopulated(id);
      if (!cart || !cart.items.length) return;

      const productOwners = [
        ...new Set(cart.items.map((item) => (item.productId as IProduct).userId.toString())),
      ];
      const ChatService = new chatService();
      for (const ownerId of productOwners) {
        if (ownerId === id) continue;

        let chat = await ChatService.checkExistChatUser1AndUser2(id, ownerId);

        if (!chat) {
          chat = await ChatService.createChatSelf({
            user1Id: id,
            user2Id: ownerId,
            status: 0,
          });

          const populatedChat = await ChatService.getChatByIdPopulate(chat._id!.toString());
          sendToUser(id, { type: "NEW_CHAT", chat: populatedChat });
        } else {
          chat.status = 0;
          await chat.save();
        }

        const messageText = `Xin chào, Cám ơn vì đã mua sản phẩm của tôi! Hãy liên hệ với tôi khi có vấn đề nhé.`;
        const message = await new messageService().create({
          senderId: ownerId,
          receiverId: id,
          message: messageText,
        });

        sendToUser(id, { type: "MESSAGE", message });
      }
      return;
    } catch (error) {
      next(error);
    }
  };
}
