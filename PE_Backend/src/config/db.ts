import mongoose from "mongoose";

let isConnected = false;

export const connectDB = async (): Promise<void> => {
  try {
    if (isConnected) return;

    await mongoose.connect(process.env.MONGO_URI as string, {
      autoIndex: true,    
      maxPoolSize: 10,       
      serverSelectionTimeoutMS: 5000, 
    });

    isConnected = true;
  } catch (error) {
    // In test environment, log error but don't exit
    if (process.env.NODE_ENV === 'test' || process.env.JEST_WORKER_ID) {
      console.error('Database connection failed in test environment:', error);
      throw error;
    }
    process.exit(1);
  }
};
