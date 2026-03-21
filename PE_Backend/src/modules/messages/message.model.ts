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

// Indexes for query performance
MessageSchema.index({ senderId: 1, receiverId: 1, dateSent: 1 }); // Compound index for getMessagesByChatId
MessageSchema.index({ receiverId: 1, isRead: 1 }); // Index for unread queries
MessageSchema.index({ dateSent: 1 }); // Index for chronological ordering

export default mongoose.model<IMessage>("messages", MessageSchema);
