import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";

export interface IPost extends Document {
  content: string;
  imageUrl?: string;
  authorId: Types.ObjectId | IUser;
  createdAt: Date;
  updatedAt: Date;
}

export const PostSchema = new mongoose.Schema<IPost>(
  {
    content: { type: String, required: true, trim: true, maxlength: 1000 },
    imageUrl: { type: String, default: "" },
    authorId: { type: Types.ObjectId, ref: "users", required: true },
  },
  { timestamps: true }
);

export default mongoose.model<IPost>("posts", PostSchema);
