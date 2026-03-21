import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";
import { IPost } from "./post.model";

export const reactionTypes = ["like", "love", "haha", "wow", "sad", "angry"] as const;
export type ReactionType = (typeof reactionTypes)[number];

export interface IPostReaction extends Document {
  postId: Types.ObjectId | IPost;
  userId: Types.ObjectId | IUser;
  type: ReactionType;
  createdAt: Date;
  updatedAt: Date;
}

export const PostReactionSchema = new mongoose.Schema<IPostReaction>(
  {
    postId: { type: Types.ObjectId, ref: "posts", required: true, index: true },
    userId: { type: Types.ObjectId, ref: "users", required: true },
    type: { type: String, enum: reactionTypes, required: true },
  },
  { timestamps: true }
);

PostReactionSchema.index({ postId: 1, userId: 1 }, { unique: true });

export default mongoose.model<IPostReaction>("post_reactions", PostReactionSchema);
