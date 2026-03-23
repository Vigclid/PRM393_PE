import { GenericService } from "../../core/services/base.service";
import feedbackModel, { IFeedback } from "./feedback.model";

export class feedbackService extends GenericService<IFeedback> {
    constructor() {
        super(feedbackModel);
    }

    getAllFeedbackByProductId = async (id: string) => {
        return feedbackModel.find({ productId: id }).populate("userId");
    }

    createNewFeedback = async (data: Partial<IFeedback>) => {
        return await feedbackModel.create(data);
    }

    updateFeedback = async (id: string, data: Partial<IFeedback>) => {
        return await feedbackModel.findByIdAndUpdate(id, data, { new: true });
    }

    getAvarageRatingByProductId = async (id: string) => {
        return await feedbackModel.aggregate([
            { $match: { productId: id } },
            { $group: { _id: "$productId", averageRating: { $avg: "$rating" } } },
        ]);
    }
}