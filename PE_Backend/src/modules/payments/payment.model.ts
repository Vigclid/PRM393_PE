import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";

export interface IQrInformation extends Document {
  qrCode: string;
  amount: number;
  description: string;
}
export interface IPayment extends Document {
  userId: Types.ObjectId | IUser | string;
  dateCreated: string | undefined;
  amount: number;
  status: boolean;
  orderCode?: number;
}

export const PaymentSchema = new mongoose.Schema<IPayment>({
  userId: { type: Types.ObjectId, ref: "users", required: true },
  dateCreated: {
    type: Date,
    default: () => new Date(new Date().getTime() + 7 * 60 * 60 * 1000),
  },
  amount: { type: Number, required: true },
  status: { type: Boolean, required: true },
  orderCode: { type: String, required: true },
});

export default mongoose.model<IPayment>("payments", PaymentSchema);
