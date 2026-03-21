"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.commentService = void 0;
const base_service_1 = require("../../core/services/base.service");
const comment_model_1 = __importDefault(require("./comment.model"));
class commentService extends base_service_1.GenericService {
    constructor() {
        super(comment_model_1.default);
        //Functions here
        this.saveArtworkComment = async (data) => {
            try {
                const comment = new comment_model_1.default({
                    ...data
                });
                return await comment.save();
            }
            catch (error) {
                throw new Error(`Save comment failed: ${error.message}`);
            }
        };
        this.countTotalComment = async (artworkId) => {
            try {
                const total = await comment_model_1.default.countDocuments({ artworkId });
                return total;
            }
            catch (error) {
                throw new Error(`Count comments failed: ${error.message}`);
            }
        };
        this.getCommentsByArtworkId = async (artworkId) => {
            if (!artworkId)
                return [];
            return await comment_model_1.default.find({ artworkId: artworkId }).populate("userId");
        };
    }
}
exports.commentService = commentService;
