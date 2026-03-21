import { NextFunction, Request, Response } from "express";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { ReactionType, reactionTypes } from "./post-reaction.model";
import { PostService } from "./post.service";

const isReactionType = (value: string): value is ReactionType =>
  reactionTypes.includes(value as ReactionType);

export class PostController {
  constructor(private readonly postService: PostService) {}

  private getCurrentUserId(req: Request): string {
    const user = (req as Request & { user?: { id?: string | number } }).user;
    return (user?.id ?? "").toString();
  }

  getFeed = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = this.getCurrentUserId(req);
      const feed = await this.postService.getFeed(userId);
      res.json(responseWrapper("success", "Fetched successfully", feed));
    } catch (error) {
      next(error);
    }
  };

  createPost = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = this.getCurrentUserId(req);
      const content = (req.body.content as string | undefined) ?? "";
      const imageBase64 = (req.body.image as string | undefined) ?? "";
      const post = await this.postService.createPost(userId, content, imageBase64);
      res.status(201).json(responseWrapper("success", "Created successfully", post));
    } catch (error) {
      next(error);
    }
  };

  reactToPost = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = this.getCurrentUserId(req);
      const type = ((req.body.type as string | undefined) ?? "").trim().toLowerCase();
      if (!isReactionType(type)) {
        return res.status(400).json(responseWrapper("error", "Invalid reaction type"));
      }
      const post = await this.postService.react(req.params.postId, userId, type);
      res.json(responseWrapper("success", "Reaction updated successfully", post));
    } catch (error) {
      next(error);
    }
  };

  addComment = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = this.getCurrentUserId(req);
      const content = (req.body.content as string | undefined) ?? "";
      const imageBase64 = (req.body.image as string | undefined) ?? "";
      const post = await this.postService.addComment(req.params.postId, userId, content, imageBase64);
      res.status(201).json(responseWrapper("success", "Comment added successfully", post));
    } catch (error) {
      next(error);
    }
  };

  addReply = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = this.getCurrentUserId(req);
      const content = (req.body.content as string | undefined) ?? "";
      const imageBase64 = (req.body.image as string | undefined) ?? "";
      const post = await this.postService.addComment(
        req.params.postId,
        userId,
        content,
        imageBase64,
        req.params.commentId
      );
      res.status(201).json(responseWrapper("success", "Reply added successfully", post));
    } catch (error) {
      next(error);
    }
  };

  reactToComment = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = this.getCurrentUserId(req);
      const type = ((req.body.type as string | undefined) ?? "").trim().toLowerCase();
      if (!isReactionType(type)) {
        return res.status(400).json(responseWrapper("error", "Invalid reaction type"));
      }
      const post = await this.postService.reactComment(req.params.commentId, userId, type);
      res.json(responseWrapper("success", "Reaction updated successfully", post));
    } catch (error) {
      next(error);
    }
  };
}
