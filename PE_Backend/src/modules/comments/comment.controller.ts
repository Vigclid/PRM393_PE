import { commentService } from './comment.service';
import { IComment } from './comment.model';
import { GenericController } from "../../core/controllers/base.controller";
import { Request, Response } from "express";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import jwt from "jsonwebtoken";

export class CommentController extends GenericController<IComment> {
    private CommentService: commentService;
    constructor(commentService: commentService) {
        super(commentService);
        this.CommentService = commentService;
    }

    //functions here
    saveComment = async (req: Request, res: Response) => {
        try {
            const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
                id: string;
            };
            req.body.userId = id;
            const comment = await this.CommentService.saveArtworkComment(req.body);
            res.json(responseWrapper("success", "Comment saved successfully", comment));
        } catch (error) {
            res.status(500).json(responseWrapper("error", "Save comment failed", error));
        }
    };

    countCommentByArtworkId = async (req: Request, res: Response) => {
        try {
            const artworkId = req.params.id;
            const total = await this.CommentService.countTotalComment(artworkId);
            res.json(responseWrapper("success", "Total comments fetched successfully", { total }))
        } catch (err) {
            res.status(500).json(responseWrapper("error", "Count comment failed", err))
        }
    }

    getCommentByArtworkId = async (req: Request, res: Response) => {
        try {
            const artworkId = req.params.artworkId;
            const comments = await this.CommentService.getCommentsByArtworkId(artworkId);
            res.json(responseWrapper("success", "Comments fetched successfully", comments.reverse()));
        } catch (error) {
            res.status(500).json(responseWrapper("error", "Fetch comments failed", error));
        }
    };
}
