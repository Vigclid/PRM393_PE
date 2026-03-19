import { GenericService } from "../../core/services/base.service";
import chatModel, { IChat } from "./chat.model";

export class chatService extends GenericService<IChat> {
  constructor() {
    super(chatModel);
  }
  getChatSelf = async (id: string) =>
    chatModel
      .find({ $or: [{ user1Id: id }, { user2Id: id }] })
      .populate("user1Id")
      .populate("user2Id");

  createChatSelf = async (data: Partial<IChat>) => chatModel.create(data);

  getChatByIdPopulate = async (id: string) =>
    chatModel.findById(id).populate("user1Id").populate("user2Id");

  checkExistChatUser1AndUser2 = async (user1Id: string, user2Id: string) =>
    chatModel
      .findOne({
        $or: [
          { user1Id, user2Id },
          { user1Id: user2Id, user2Id: user1Id },
        ],
      })
      .populate("user1Id")
      .populate("user2Id");

  markAsReadByUserId = async (id: string) =>
    await chatModel.updateMany(
      { $or: [{ user1Id: id }, { user2Id: id }] },
      { $set: { status: 1 } }
    );
}
