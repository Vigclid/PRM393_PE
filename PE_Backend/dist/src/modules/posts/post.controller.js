"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostController = void 0;
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const post_reaction_model_1 = require("./post-reaction.model");
const isReactionType = (value) => post_reaction_model_1.reactionTypes.includes(value);
class PostController {
    constructor(postService) {
        this.postService = postService;
        this.getFeed = async (req, res, next) => {
            try {
                const userId = req.user?.id?.toString() ?? "";
                const feed = await this.postService.getFeed(userId);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", feed));
            }
            catch (error) {
                next(error);
            }
        };
        this.createPost = async (req, res, next) => {
            try {
                const userId = req.user?.id?.toString() ?? "";
                const content = req.body.content ?? "";
                const post = await this.postService.createPost(userId, content);
                res.status(201).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Created successfully", post));
            }
            catch (error) {
                next(error);
            }
        };
        this.reactToPost = async (req, res, next) => {
            try {
                const userId = req.user?.id?.toString() ?? "";
                const type = (req.body.type ?? "").trim().toLowerCase();
                if (!isReactionType(type)) {
                    return res.status(400).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Invalid reaction type"));
                }
                const post = await this.postService.react(req.params.postId, userId, type);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Reaction updated successfully", post));
            }
            catch (error) {
                next(error);
            }
        };
        this.addComment = async (req, res, next) => {
            try {
                const userId = req.user?.id?.toString() ?? "";
                const content = req.body.content ?? "";
                const post = await this.postService.addComment(req.params.postId, userId, content);
                res.status(201).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Comment added successfully", post));
            }
            catch (error) {
                next(error);
            }
        };
        this.addReply = async (req, res, next) => {
            try {
                const userId = req.user?.id?.toString() ?? "";
                const content = req.body.content ?? "";
                const post = await this.postService.addComment(req.params.postId, userId, content, req.params.commentId);
                res.status(201).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Reply added successfully", post));
            }
            catch (error) {
                next(error);
            }
        };
    }
}
exports.PostController = PostController;
