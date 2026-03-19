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
}
