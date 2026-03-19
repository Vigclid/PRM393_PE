import mongoose, { Document } from "mongoose";

export interface IRole extends Document {
  name: string;
}

export const RoleSchema = new mongoose.Schema<IRole>({
  name: { type: String, required: true },
});

export default mongoose.model<IRole>("roles", RoleSchema);
