import mongoose, { Document, Types } from "mongoose";
import { IUser } from "../users/user.model";

export type ReportType = "Help" | "Bug" | "Advice";
export type ReportStatus = "Pending" | "InProgress" | "Resolved" | "Closed";

export interface IReply {
  senderId: Types.ObjectId | IUser;
  message: string;
  createdAt: Date;
}

export interface IReport extends Document {
  userId: Types.ObjectId | IUser;
  typeReport: ReportType;
  title: string;
  description: string;
  status: ReportStatus;
  replies: IReply[];
  createdAt: Date;
  updatedAt: Date;
}

const ReplySchema = new mongoose.Schema<IReply>(
  {
    senderId: { type: Types.ObjectId, ref: "users", required: true },
    message: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const ReportSchema = new mongoose.Schema<IReport>(
  {
    userId: { type: Types.ObjectId, ref: "users", required: true },
    typeReport: {
      type: String,
      enum: ["Help", "Bug", "Advice"],
      required: true,
    },
    title: { type: String, required: true },
    description: { type: String, required: true },
    status: {
      type: String,
      enum: ["Pending", "InProgress", "Resolved", "Closed"],
      default: "Pending",
    },
    replies: [ReplySchema],
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

export default mongoose.model<IReport>("reports", ReportSchema);
