import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";
import { IProduct } from "../products/product.model";

export interface IFeedback extends Document {
    userId: Types.ObjectId | IUser;
    productId: Types.ObjectId | IProduct;
    rating: number;
    comment: string;
    createdAt: Date;
}

const feedbackSchema = new mongoose.Schema<IFeedback>({
    userId: { type: Types.ObjectId, ref: "users", required: true },
    productId: { type: Types.ObjectId, ref: "products", required: true },
    rating: { type: Number, required: true },
    comment: { type: String, required: true },
    createdAt: { type: Date, default: Date.now},
})

export default mongoose.model<IFeedback>("feedbacks", feedbackSchema);