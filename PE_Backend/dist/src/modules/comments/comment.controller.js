"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommentController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
class CommentController extends base_controller_1.GenericController {
    constructor(commentService) {
        super(commentService);
        //functions here
        this.saveComment = async (req, res) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                req.body.userId = id;
                const comment = await this.CommentService.saveArtworkComment(req.body);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Comment saved successfully", comment));
            }
            catch (error) {
                res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Save comment failed", error));
            }
        };
        this.countCommentByArtworkId = async (req, res) => {
            try {
                const artworkId = req.params.id;
                const total = await this.CommentService.countTotalComment(artworkId);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Total comments fetched successfully", { total }));
            }
            catch (err) {
                res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Count comment failed", err));
            }
        };
        this.getCommentByArtworkId = async (req, res) => {
            try {
                const artworkId = req.params.artworkId;
                const comments = await this.CommentService.getCommentsByArtworkId(artworkId);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Comments fetched successfully", comments.reverse()));
            }
            catch (error) {
                res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Fetch comments failed", error));
            }
        };
        this.CommentService = commentService;
    }
}
exports.CommentController = CommentController;
