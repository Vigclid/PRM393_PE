import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";
import { IProduct } from "../products/product.model";

export interface ICartItem {
  productId: Types.ObjectId | IProduct;
  quantity: number;
  priceAtTime: number;
}

export interface ICart extends Document {
  userId: Types.ObjectId | IUser;
  items: ICartItem[];
  totalPrice: number;
  createdAt: Date;
  updatedAt: Date;
}

const CartItemSchema = new mongoose.Schema<ICartItem>({
  productId: { type: Types.ObjectId, ref: "products", required: true },
  quantity: { type: Number, required: true, default: 1 },
  priceAtTime: { type: Number, required: true },
});

export const CartSchema = new mongoose.Schema<ICart>({
  userId: { type: Types.ObjectId, ref: "users", required: true },
  items: { type: [CartItemSchema], required: true },
  totalPrice: { type: Number, required: true, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

CartSchema.pre("save", function (next) {
  this.totalPrice = this.items.reduce((sum, item) => sum + item.quantity * item.priceAtTime, 0);
  this.updatedAt = new Date();
  next();
});
export default mongoose.model<ICart>("carts", CartSchema);
