import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";
import { IPost } from "./post.model";

export interface IPostComment extends Document {
  postId: Types.ObjectId | IPost;
  authorId: Types.ObjectId | IUser;
  parentCommentId?: Types.ObjectId | IPostComment | null;
  content: string;
  imageUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export const PostCommentSchema = new mongoose.Schema<IPostComment>(
  {
    postId: { type: Types.ObjectId, ref: "posts", required: true, index: true },
    authorId: { type: Types.ObjectId, ref: "users", required: true },
    parentCommentId: { type: Types.ObjectId, ref: "post_comments", default: null },
    content: { type: String, required: true, trim: true, maxlength: 1000 },
    imageUrl: { type: String, default: "" },
  },
  { timestamps: true }
);

PostCommentSchema.index({ postId: 1, createdAt: 1 });

export default mongoose.model<IPostComment>("post_comments", PostCommentSchema);
