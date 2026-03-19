import { GenericService } from "../../core/services/base.service";
import messageModel, { IMessage } from "./message.model";

export class messageService extends GenericService<IMessage> {
  constructor() {
    super(messageModel);
  }

  getMessagesSelf = async (id: string) => {
    return messageModel.find({ $or: [{ senderId: id }, { receiverId: id }] });
  };

  getSelftChatWithUserId = async (user1Id: string, user2Id: string) => {
    return messageModel
      .find({
        $or: [
          { senderId: user1Id, receiverId: user2Id },
          { senderId: user2Id, receiverId: user1Id },
        ],
      })
      .populate("senderId")
      .populate("receiverId");
  };
}
