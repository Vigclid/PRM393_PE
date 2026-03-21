import { Types } from "mongoose";
import postCommentModel from "./post-comment.model";
import postCommentReactionModel from "./post-comment-reaction.model";
import postModel from "./post.model";
import postReactionModel, { ReactionType, reactionTypes } from "./post-reaction.model";
import { uploadImage } from "../../utils/imageUtils";

export interface IPostAuthorDto {
  id: string;
  email: string;
  displayName: string;
  avatarUrl: string;
}

export interface IPostCommentDto {
  id: string;
  content: string;
  imageUrl: string;
  createdAt: string;
  author: IPostAuthorDto;
  reactions: {
    total: number;
    myReaction: ReactionType | null;
    items: Array<{ type: ReactionType; count: number }>;
  };
  replies: IPostCommentDto[];
}

export interface IPostFeedItemDto {
  id: string;
  content: string;
  imageUrl: string;
  createdAt: string;
  updatedAt: string;
  author: IPostAuthorDto;
  comments: IPostCommentDto[];
  reactions: {
    total: number;
    myReaction: ReactionType | null;
    items: Array<{ type: ReactionType; count: number }>;
  };
}

type UserLean = {
  _id: Types.ObjectId;
  email: string;
  firstName?: string;
  lastName?: string;
  profilePicture?: string;
};

const isReactionType = (value: string): value is ReactionType =>
  reactionTypes.includes(value as ReactionType);

const emptyCounts = (): Record<ReactionType, number> => ({
  like: 0,
  love: 0,
  haha: 0,
  wow: 0,
  sad: 0,
  angry: 0,
});

export class PostService {
  private mapUser(user: UserLean): IPostAuthorDto {
    const fullName = `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim();
    const emailPrefix = user.email.split("@")[0] ?? "User";
    return {
      id: user._id.toString(),
      email: user.email,
      displayName: fullName.length > 0 ? fullName : emailPrefix,
      avatarUrl: user.profilePicture ?? "",
    };
  }

  private createReactionBag() {
    return { total: 0, myReaction: null as ReactionType | null, counts: emptyCounts() };
  }

  private toReactionSummary(bag?: { total: number; myReaction: ReactionType | null; counts: Record<ReactionType, number> }) {
    const counts = bag?.counts ?? emptyCounts();
    return {
      total: bag?.total ?? 0,
      myReaction: bag?.myReaction ?? null,
      items: reactionTypes.map((type) => ({ type, count: counts[type] })),
    };
  }

  private async uploadOptionalImage(base64Image?: string): Promise<string> {
    if (!base64Image || base64Image.trim().length === 0) return "";
    const uploaded = await uploadImage(base64Image, 3, false);
    const secureUrl = uploaded?.image?.secure_url ?? "";
    return secureUrl;
  }

  private async buildFeed(postIds: string[] | null, currentUserId: string): Promise<IPostFeedItemDto[]> {
    const postFilter = postIds === null ? {} : { _id: { $in: postIds.map((id) => new Types.ObjectId(id)) } };

    const posts = await postModel
      .find(postFilter)
      .sort({ createdAt: -1 })
      .populate<{ authorId: UserLean }>("authorId", "email firstName lastName profilePicture")
      .lean();

    if (posts.length === 0) return [];

    const ids = posts.map((post) => post._id.toString());

    const [comments, reactions] = await Promise.all([
      postCommentModel
        .find({ postId: { $in: ids } })
        .sort({ createdAt: 1 })
        .populate<{ authorId: UserLean }>("authorId", "email firstName lastName profilePicture")
        .lean(),
      postReactionModel.find({ postId: { $in: ids } }).lean(),
    ]);

    const commentIds = comments.map((comment) => comment._id);
    const commentReactions =
      commentIds.length === 0 ? [] : await postCommentReactionModel.find({ commentId: { $in: commentIds } }).lean();

    const commentsByPost = new Map<string, IPostCommentDto[]>();
    const commentReactionBag = new Map<string, { total: number; myReaction: ReactionType | null; counts: Record<ReactionType, number> }>();

    for (const comment of comments) {
      commentReactionBag.set(comment._id.toString(), this.createReactionBag());
    }

    for (const reaction of commentReactions) {
      const commentId = reaction.commentId.toString();
      const bag = commentReactionBag.get(commentId);
      if (!bag) continue;
      bag.total += 1;
      if (isReactionType(reaction.type)) {
        bag.counts[reaction.type] += 1;
      }
      if (reaction.userId.toString() === currentUserId && isReactionType(reaction.type)) {
        bag.myReaction = reaction.type;
      }
    }

    for (const postId of ids) {
      const related = comments.filter((comment) => comment.postId.toString() === postId);
      const nodeMap = new Map<string, IPostCommentDto>();
      const roots: IPostCommentDto[] = [];

      for (const comment of related) {
        const node: IPostCommentDto = {
          id: comment._id.toString(),
          content: comment.content,
          imageUrl: comment.imageUrl ?? "",
          createdAt: comment.createdAt.toISOString(),
          author: this.mapUser(comment.authorId as UserLean),
          reactions: this.toReactionSummary(commentReactionBag.get(comment._id.toString())),
          replies: [],
        };
        nodeMap.set(node.id, node);
      }

      for (const comment of related) {
        const id = comment._id.toString();
        const current = nodeMap.get(id);
        if (!current) continue;

        const parentId = comment.parentCommentId?.toString();
        if (parentId && nodeMap.has(parentId)) {
          const parent = nodeMap.get(parentId);
          if (parent) parent.replies.push(current);
          continue;
        }
        roots.push(current);
      }

      commentsByPost.set(postId, roots);
    }

    const reactionsByPost = new Map<
      string,
      { total: number; myReaction: ReactionType | null; counts: Record<ReactionType, number> }
    >();

    for (const postId of ids) {
      reactionsByPost.set(postId, this.createReactionBag());
    }

    for (const reaction of reactions) {
      const postId = reaction.postId.toString();
      const bag = reactionsByPost.get(postId);
      if (!bag) continue;
      bag.total += 1;
      if (isReactionType(reaction.type)) {
        bag.counts[reaction.type] += 1;
      }
      if (reaction.userId.toString() === currentUserId && isReactionType(reaction.type)) {
        bag.myReaction = reaction.type;
      }
    }

    return posts.map((post) => {
      const reactionBag = reactionsByPost.get(post._id.toString());
      return {
        id: post._id.toString(),
        content: post.content,
        imageUrl: post.imageUrl ?? "",
        createdAt: post.createdAt.toISOString(),
        updatedAt: post.updatedAt.toISOString(),
        author: this.mapUser(post.authorId as UserLean),
        comments: commentsByPost.get(post._id.toString()) ?? [],
        reactions: this.toReactionSummary(reactionBag),
      };
    });
  }

  async getFeed(currentUserId: string): Promise<IPostFeedItemDto[]> {
    return this.buildFeed(null, currentUserId);
  }

  async createPost(authorId: string, content: string, imageBase64?: string): Promise<IPostFeedItemDto> {
    const value = content.trim();
    const imageUrl = await this.uploadOptionalImage(imageBase64);
    if (!value && imageUrl.length === 0) throw new Error("Post requires text or image");
    if (value.length > 1000) throw new Error("Post content is too long");
    const created = await postModel.create({ authorId, content: value, imageUrl });
    const createdId = (created._id as Types.ObjectId).toString();
    const [item] = await this.buildFeed([createdId], authorId);
    return item;
  }

  async addComment(
    postId: string,
    authorId: string,
    content: string,
    imageBase64?: string,
    parentCommentId?: string
  ): Promise<IPostFeedItemDto> {
    const postExists = await postModel.exists({ _id: postId });
    if (!postExists) throw new Error("Post not found");

    const value = content.trim();
    const imageUrl = await this.uploadOptionalImage(imageBase64);
    if (!value && imageUrl.length === 0) throw new Error("Comment requires text or image");
    if (value.length > 1000) throw new Error("Comment content is too long");

    if (parentCommentId) {
      const parent = await postCommentModel.findOne({ _id: parentCommentId, postId });
      if (!parent) throw new Error("Parent comment not found");
    }

    await postCommentModel.create({
      postId,
      authorId,
      content: value,
      imageUrl,
      parentCommentId: parentCommentId ?? null,
    });
    const [item] = await this.buildFeed([postId], authorId);
    return item;
  }

  async react(postId: string, userId: string, type: ReactionType): Promise<IPostFeedItemDto> {
    const postExists = await postModel.exists({ _id: postId });
    if (!postExists) throw new Error("Post not found");

    const current = await postReactionModel.findOne({ postId, userId });
    if (current && current.type === type) {
      await postReactionModel.deleteOne({ _id: current._id });
    } else if (current) {
      current.type = type;
      await current.save();
    } else {
      await postReactionModel.create({ postId, userId, type });
    }

    const [item] = await this.buildFeed([postId], userId);
    return item;
  }

  async reactComment(commentId: string, userId: string, type: ReactionType): Promise<IPostFeedItemDto> {
    const comment = await postCommentModel.findById(commentId);
    if (!comment) throw new Error("Comment not found");

    const current = await postCommentReactionModel.findOne({ commentId, userId });
    if (current && current.type === type) {
      await postCommentReactionModel.deleteOne({ _id: current._id });
    } else if (current) {
      current.type = type;
      await current.save();
    } else {
      await postCommentReactionModel.create({ commentId, userId, type });
    }

    const [item] = await this.buildFeed([comment.postId.toString()], userId);
    return item;
  }
}
