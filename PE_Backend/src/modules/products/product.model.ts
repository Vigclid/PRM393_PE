import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";

export interface IProduct extends Document {
  name: string;
  description: string;
  price: number;
  imageUrl: string;
  category: string;
  rating: number;
  stock: number;
  userId: Types.ObjectId | IUser;
  createAt: Date;
}

export const ProductSchema = new mongoose.Schema<IProduct>({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  imageUrl: { type: String, required: true },
  category: { type: String, required: true },
  rating: { type: Number, required: true, default: 0 },
  stock: { type: Number, required: true, default: 0 },
  userId: { type: Types.ObjectId, ref: "users", required: true },
  createAt: { type: Date, required: true, default: new Date() },
});

export default mongoose.model<IProduct>("products", ProductSchema);
