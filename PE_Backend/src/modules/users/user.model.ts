import mongoose, { Document, Types } from "mongoose";
import { IRole } from "../roles/role.model";
export interface IUser extends Document {
  coins: string | number;
  profilePicture: string | "";
  backgroundPicture: string | "";
  firstName: string | "";
  lastName: string | "";
  address: string | "";
  phoneNumber: string | "0";
  lastLogin: string | undefined;
  CreateAt: string | undefined;
  dateOfBirth: string | undefined;
  allowCommission: boolean | false;
  biography: string | "";
  followCounts: number | 0;
  followerCount: number | 0;
  email: string;
  password: string;
  roleID: Types.ObjectId | IRole;
  loginFailedCounts: number;
  loginFailedTime: Date | null;
  isActive: boolean;
}

export const UserSchema = new mongoose.Schema<IUser>({
  coins: { type: String, required: true, default: "0" },
  profilePicture: { type: String, required: false },
  backgroundPicture: { type: String, required: false },
  firstName: { type: String, required: false },
  lastName: { type: String, required: false },
  address: { type: String, required: false },
  phoneNumber: { type: String, required: false },
  lastLogin: { type: String, required: true, default: new Date() },
  CreateAt: { type: String, required: true, default: new Date() },
  dateOfBirth: { type: String, required: false, default: "" },
  allowCommission: { type: Boolean, required: false },
  biography: { type: String, required: false },
  followCounts: { type: Number, required: false, default: 0 },
  followerCount: { type: Number, required: false, default: 0 },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  roleID: {
    type: Types.ObjectId,
    required: true,
    ref: "roles",
  },
  loginFailedCounts: { type: Number, required: false, default: 0 },
  loginFailedTime: { type: Date || null, required: false, default: null },
  isActive: { type: Boolean, required: true, default: true },
});

export default mongoose.model<IUser>("users", UserSchema);
