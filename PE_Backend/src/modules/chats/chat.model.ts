import mongoose, { Document } from "mongoose";

export interface IChat extends Document {
  user1Id: string;
  user2Id: string;
  status: number;
}

export const ChatSchema = new mongoose.Schema<IChat>({
  user1Id: { type: String, ref: "users", required: true },
  user2Id: { type: String, ref: "users", required: true },
  status: { type: Number, required: true },
});

export default mongoose.model<IChat>("chats", ChatSchema);
