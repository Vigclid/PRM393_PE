import mongoose, { Schema, Document } from "mongoose";

export interface IAIChat extends Document {
  userId: mongoose.Types.ObjectId;
  messages: {
    role: "user" | "model";
    content: string;
    timestamp: Date;
  }[];
  productId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const aiChatSchema = new Schema<IAIChat>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    messages: [
      {
        role: {
          type: String,
          enum: ["user", "model"],
          required: true,
        },
        content: {
          type: String,
          required: true,
        },
        timestamp: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    productId: {
      type: Schema.Types.ObjectId,
      ref: "Product",
    },
  },
  { timestamps: true }
);

export const AIChatModel = mongoose.model<IAIChat>("AIChat", aiChatSchema);
