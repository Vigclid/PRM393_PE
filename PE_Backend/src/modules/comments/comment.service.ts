import { GenericService } from "../../core/services/base.service";
import commentModel, { IComment } from "./comment.model";

export class commentService extends GenericService<IComment> {
    constructor() {
        super(commentModel);
    }

    //Functions here

    saveArtworkComment = async (data: Partial<IComment>) => {
        try {
            const comment = new commentModel({
                ...data
            });
            return await comment.save();
        } catch (error: any) {
            throw new Error(`Save comment failed: ${error.message}`);
        }
    };
    countTotalComment = async (artworkId: string) => {
        try {
            const total = await commentModel.countDocuments({ artworkId });
            return total;
        } catch (error: any) {
            throw new Error(`Count comments failed: ${error.message}`);
        }
    };

    getCommentsByArtworkId = async (artworkId: string) => {
        if (!artworkId) return [];
        return await commentModel.find({ artworkId: artworkId }).populate("userId");
    }
}