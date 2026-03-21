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

// Indexes for performance optimization
ChatSchema.index({ user1Id: 1, user2Id: 1 }, { unique: true });
ChatSchema.index({ user1Id: 1 });
ChatSchema.index({ user2Id: 1 });

export default mongoose.model<IChat>("chats", ChatSchema);
