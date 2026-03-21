"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostService = void 0;
const mongoose_1 = require("mongoose");
const post_comment_model_1 = __importDefault(require("./post-comment.model"));
const post_model_1 = __importDefault(require("./post.model"));
const post_reaction_model_1 = __importStar(require("./post-reaction.model"));
const isReactionType = (value) => post_reaction_model_1.reactionTypes.includes(value);
class PostService {
    mapUser(user) {
        const fullName = `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim();
        const emailPrefix = user.email.split("@")[0] ?? "User";
        return {
            id: user._id.toString(),
            email: user.email,
            displayName: fullName.isNotEmpty ? fullName : emailPrefix,
            avatarUrl: user.profilePicture ?? "",
        };
    }
    async buildFeed(postIds, currentUserId) {
        const postFilter = postIds === null ? {} : { _id: { $in: postIds.map((id) => new mongoose_1.Types.ObjectId(id)) } };
        const posts = await post_model_1.default
            .find(postFilter)
            .sort({ createdAt: -1 })
            .populate("authorId", "email firstName lastName profilePicture")
            .lean();
        if (posts.length === 0)
            return [];
        const ids = posts.map((post) => post._id.toString());
        const [comments, reactions] = await Promise.all([
            post_comment_model_1.default
                .find({ postId: { $in: ids } })
                .sort({ createdAt: 1 })
                .populate("authorId", "email firstName lastName profilePicture")
                .lean(),
            post_reaction_model_1.default.find({ postId: { $in: ids } }).lean(),
        ]);
        const commentsByPost = new Map();
        for (const postId of ids) {
            const related = comments.filter((comment) => comment.postId.toString() === postId);
            const nodeMap = new Map();
            const roots = [];
            for (const comment of related) {
                const node = {
                    id: comment._id.toString(),
                    content: comment.content,
                    createdAt: comment.createdAt.toISOString(),
                    author: this.mapUser(comment.authorId),
                    replies: [],
                };
                nodeMap.set(node.id, node);
            }
            for (const comment of related) {
                const id = comment._id.toString();
                const current = nodeMap.get(id);
                if (!current)
                    continue;
                const parentId = comment.parentCommentId?.toString();
                if (parentId && nodeMap.has(parentId)) {
                    const parent = nodeMap.get(parentId);
                    if (parent)
                        parent.replies.push(current);
                    continue;
                }
                roots.push(current);
            }
            commentsByPost.set(postId, roots);
        }
        const reactionsByPost = new Map();
        for (const postId of ids) {
            reactionsByPost.set(postId, {
                total: 0,
                myReaction: null,
                counts: { like: 0, love: 0, haha: 0, wow: 0, sad: 0, angry: 0 },
            });
        }
        for (const reaction of reactions) {
            const postId = reaction.postId.toString();
            const bag = reactionsByPost.get(postId);
            if (!bag)
                continue;
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
            const counts = reactionBag?.counts ?? { like: 0, love: 0, haha: 0, wow: 0, sad: 0, angry: 0 };
            return {
                id: post._id.toString(),
                content: post.content,
                createdAt: post.createdAt.toISOString(),
                updatedAt: post.updatedAt.toISOString(),
                author: this.mapUser(post.authorId),
                comments: commentsByPost.get(post._id.toString()) ?? [],
                reactions: {
                    total: reactionBag?.total ?? 0,
                    myReaction: reactionBag?.myReaction ?? null,
                    items: post_reaction_model_1.reactionTypes.map((type) => ({ type, count: counts[type] })),
                },
            };
        });
    }
    async getFeed(currentUserId) {
        return this.buildFeed(null, currentUserId);
    }
    async createPost(authorId, content) {
        const value = content.trim();
        if (!value)
            throw new Error("Post content is required");
        if (value.length > 1000)
            throw new Error("Post content is too long");
        const created = await post_model_1.default.create({ authorId, content: value });
        const [item] = await this.buildFeed([created._id.toString()], authorId);
        return item;
    }
    async addComment(postId, authorId, content, parentCommentId) {
        const postExists = await post_model_1.default.exists({ _id: postId });
        if (!postExists)
            throw new Error("Post not found");
        const value = content.trim();
        if (!value)
            throw new Error("Comment content is required");
        if (value.length > 1000)
            throw new Error("Comment content is too long");
        if (parentCommentId) {
            const parent = await post_comment_model_1.default.findOne({ _id: parentCommentId, postId });
            if (!parent)
                throw new Error("Parent comment not found");
        }
        await post_comment_model_1.default.create({
            postId,
            authorId,
            content: value,
            parentCommentId: parentCommentId ?? null,
        });
        const [item] = await this.buildFeed([postId], authorId);
        return item;
    }
    async react(postId, userId, type) {
        const postExists = await post_model_1.default.exists({ _id: postId });
        if (!postExists)
            throw new Error("Post not found");
        const current = await post_reaction_model_1.default.findOne({ postId, userId });
        if (current && current.type === type) {
            await post_reaction_model_1.default.deleteOne({ _id: current._id });
        }
        else if (current) {
            current.type = type;
            await current.save();
        }
        else {
            await post_reaction_model_1.default.create({ postId, userId, type });
        }
        const [item] = await this.buildFeed([postId], userId);
        return item;
    }
}
exports.PostService = PostService;
