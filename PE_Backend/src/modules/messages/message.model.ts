import mongoose, { Document } from "mongoose";

export interface IMessage extends Document {
  senderId: string;
  receiverId: string;
  message: string;
  dateSent: Date;
  isRead: number;
}

export const MessageSchema = new mongoose.Schema<IMessage>({
  senderId: { type: String, ref: "users", required: true },
  receiverId: { type: String, ref: "users", required: true },
  message: { type: String, required: true },
  dateSent: { type: Date, required: true, default: Date.now },
  isRead: { type: Number, required: true, default: 0 },
});

export default mongoose.model<IMessage>("messages", MessageSchema);
