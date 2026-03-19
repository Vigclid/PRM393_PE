import mongoose, { Document, Types } from "mongoose";
import { IProduct } from "../products/product.model";
import { IUser } from "../users/user.model";

export interface IBillItem {
  productId: Types.ObjectId | IProduct;
  quantity: number;
  priceAtTime: number;
}

export interface IBill extends Document {
  userId: Types.ObjectId | IUser;
  items: IBillItem[];
  totalPrice: number;
  createdAt: Date;
}

const BillItemSchema = new mongoose.Schema<IBillItem>({
  productId: { type: Types.ObjectId, ref: "products", required: true },
  quantity: { type: Number, required: true },
  priceAtTime: { type: Number, required: true },
});

const BillSchema = new mongoose.Schema<IBill>({
  userId: { type: Types.ObjectId, ref: "users", required: true },
  items: { type: [BillItemSchema], required: true },
  totalPrice: { type: Number, required: true, default: 0 },
  createdAt: { type: Date, default: Date.now },
});

BillSchema.pre("save", function (next) {
  this.totalPrice = this.items.reduce((sum, item) => sum + item.quantity * item.priceAtTime, 0);
  next();
});

export default mongoose.model<IBill>("bills", BillSchema);
