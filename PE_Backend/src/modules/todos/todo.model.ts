import mongoose, { Document } from "mongoose";

export interface ITodo extends Document {
  text: string;
  done: boolean;
  createdAt: Date;
  userId: String;
}

export const TodoSchema = new mongoose.Schema<ITodo>({
  text: { type: String, required: true },
  done: { type: Boolean, required: true, default: false },
  userId: { type: String, ref: "users", required: false },
  createdAt: { type: Date, required: false, default: new Date() },
});

export default mongoose.model<ITodo>("todos", TodoSchema);
