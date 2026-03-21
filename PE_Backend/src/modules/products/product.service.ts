import { GenericService } from "../../core/services/base.service";
import productModel, { IProduct } from "./product.model";

export class productService extends GenericService<IProduct> {
  constructor() {
    super(productModel);
  }
  getProductPopulated = async () => {
    return await productModel.find().populate("userId");
  };
  getMyProducts = async (userId: string) => {
    return await productModel.find({ userId }).populate("userId");
  };
  getAllProductsWithAverageRating = async () => {
    return await productModel.aggregate([
      {
        $lookup: {
          from: "feedbacks",
          localField: "_id",
          foreignField: "productId",
          as: "allFeedbacks"
        }
      },
      {
        $addFields: {
          averageRating: {
            $ifNull: [
              { $avg: "$allFeedbacks.rating" },
              0
            ]
          },
          totalReviews: { $size: "$allFeedbacks" }
        }
      },
      {
        $project: {
          allFeedbacks: 0
        }
      },
      {
        $sort: { createAt: -1 }
      }
    ]);
  }

}
