import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";
import { IPostComment } from "./post-comment.model";
import { ReactionType, reactionTypes } from "./post-reaction.model";

export interface IPostCommentReaction extends Document {
  commentId: Types.ObjectId | IPostComment;
  userId: Types.ObjectId | IUser;
  type: ReactionType;
  createdAt: Date;
  updatedAt: Date;
}

export const PostCommentReactionSchema = new mongoose.Schema<IPostCommentReaction>(
  {
    commentId: { type: Types.ObjectId, ref: "post_comments", required: true, index: true },
    userId: { type: Types.ObjectId, ref: "users", required: true },
    type: { type: String, enum: reactionTypes, required: true },
  },
  { timestamps: true }
);

PostCommentReactionSchema.index({ commentId: 1, userId: 1 }, { unique: true });

export default mongoose.model<IPostCommentReaction>("post_comment_reactions", PostCommentReactionSchema);
