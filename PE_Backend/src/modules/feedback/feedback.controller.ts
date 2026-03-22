import { GenericController } from "../../core/controllers/base.controller";
import { Request, Response } from "express";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import jwt from "jsonwebtoken";
import { feedbackService } from "./feedback.service";
import { IFeedback } from "./feedback.model";

export class feedbackController extends GenericController<IFeedback> {
    private FeedbackService: feedbackService;
    constructor(feedbackService: feedbackService) {
        super(feedbackService);
        this.FeedbackService = feedbackService;
    }

    getAllFeedbackByProductId = async (req: Request, res: Response) => {
        const { id } = req.params;
        try {
            const result = await this.FeedbackService.getAllFeedbackByProductId(id);
            res.json(responseWrapper("success", "Fetched successfully", result));
        } catch (err) {
            res.status(500).json(responseWrapper("error", "Get feedback failed", err));
        }
    }

    createNewFeedback = async (req: Request, res: Response) => {
        try {
            const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
                id: string;
            };
            req.body.userId = id;
            const result = await this.FeedbackService.createNewFeedback(req.body);
            res.json(responseWrapper("success", "Feedback created successfully", result));
        } catch (err: any) {
            res.status(500).json(responseWrapper("error", "Create feedback failed", err.message));
        }
    }


    getAvarageRatingByProductId = async (req: Request, res: Response) => {
        const { id } = req.params;
        try {
            const result = await this.FeedbackService.getAvarageRatingByProductId(id);
            res.json(responseWrapper("success", "Fetched successfully", result));
        } catch (err) {
            res.status(500).json(responseWrapper("error", "Get average rating failed", err));
        }
    }
}