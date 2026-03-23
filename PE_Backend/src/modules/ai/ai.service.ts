import axios from "axios";
import { AIChatModel, IAIChat } from "./ai.model";
import mongoose from "mongoose";

export class AIService {
  private apiKey = process.env.AI_API_KEY;
  private apiUrl = process.env.AI_API_URL || "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash";

  async sendMessage(
    userId: string,
    userMessage: string,
    productId?: string
  ): Promise<{ response: string; chatId: string }> {
    try {
      // Lấy hoặc tạo chat session
      let chat = await AIChatModel.findOne({
        userId: new mongoose.Types.ObjectId(userId),
        productId: productId ? new mongoose.Types.ObjectId(productId) : null,
      });

      if (!chat) {
        chat = new AIChatModel({
          userId: new mongoose.Types.ObjectId(userId),
          productId: productId ? new mongoose.Types.ObjectId(productId) : null,
          messages: [],
        });
      }

      // Thêm user message
      chat.messages.push({
        role: "user",
        content: userMessage,
        timestamp: new Date(),
      });

      // Gọi AI API
      const aiResponse = await this.callAIAPI(chat.messages);

      // Thêm AI response
      chat.messages.push({
        role: "model",
        content: aiResponse,
        timestamp: new Date(),
      });

      await chat.save();

      return {
        response: aiResponse,
        chatId: (chat._id as mongoose.Types.ObjectId).toString(),
      };
    } catch (error) {
      throw new Error(`AI Service Error: ${error}`);
    }
  }

  private async callAIAPI(
    messages: { role: string; content: string; timestamp: Date }[]
  ): Promise<string> {
    // Add system instruction at the beginning
    const systemInstruction = `You are a product advisor. Answer in under 200 words.
- Answer the main question FIRST with specific numbers/prices
- Then briefly explain
- Do NOT cut off mid-sentence
- Use the same language as the user
- Be direct and to the point`;

    // Format messages for Gemini API with system instruction
    const contents = [
      {
        role: "user",
        parts: [{ text: systemInstruction }],
      },
      ...messages.map((msg) => ({
        role: msg.role === "user" ? "user" : "model",
        parts: [{ text: msg.content }],
      })),
    ];

    // URL từ .env đã có đầy đủ, chỉ cần thêm :generateContent
    const url = `${this.apiUrl}:generateContent`;

    try {
      const response = await this.retryRequest(url, {
        contents: contents,
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 800,
          topP: 0.95,
          topK: 40,
        },
      });

      const textContent = response.data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!textContent) {
        throw new Error("No text content in response");
      }

      return textContent;
    } catch (error: any) {
      
      // Fallback: Return mock response if rate limited
      if (error.response?.status === 429 || error.message?.includes("429")) {
        return this.getMockResponse();
      }
      
      throw new Error(`Failed to call Gemini API: ${error.message}`);
    }
  }

  private getMockResponse(): string {
    const mockResponses = [
      "Sản phẩm này có chất lượng tốt và giá cả hợp lý. Tôi khuyên bạn nên mua!",
      "Đây là một lựa chọn tuyệt vời cho nhu cầu của bạn. Hãy xem xét thêm các đánh giá từ khách hàng khác.",
      "Sản phẩm này rất phổ biến và được nhiều người yêu thích. Bạn có thể tin tưởng vào chất lượng của nó.",
      "Tôi có thể giúp bạn tìm kiếm sản phẩm tương tự nếu bạn muốn so sánh giá.",
      "Sản phẩm này có đặc điểm nổi bật là... Bạn có muốn biết thêm chi tiết không?",
    ];
    return mockResponses[Math.floor(Math.random() * mockResponses.length)];
  }

  private async retryRequest(url: string, data: any, retries = 5): Promise<any> {
    for (let i = 0; i < retries; i++) {
      try {
        const response = await axios.post(url, data, {
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": this.apiKey,
          },
        });
        return response;
      } catch (error: any) {
        
        if (error.response?.status === 429 && i < retries - 1) {
          // Rate limited, wait and retry with longer delay
          const delay = Math.pow(2, i + 1) * 2000; // 4s, 8s, 16s, 32s, 64s
          await new Promise((resolve) => setTimeout(resolve, delay));
        } else {
          throw error;
        }
      }
    }
  }

  async getChatHistory(userId: string, productId?: string): Promise<IAIChat | null> {
    try {
      const query: any = { userId: new mongoose.Types.ObjectId(userId) };
      if (productId) {
        query.productId = new mongoose.Types.ObjectId(productId);
      }

      return await AIChatModel.findOne(query);
    } catch (error) {
      throw new Error(`Failed to get chat history: ${error}`);
    }
  }

  async clearChatHistory(userId: string, productId?: string): Promise<void> {
    try {
      const query: any = { userId: new mongoose.Types.ObjectId(userId) };
      if (productId) {
        query.productId = new mongoose.Types.ObjectId(productId);
      }

      await AIChatModel.deleteOne(query);
    } catch (error) {
      throw new Error(`Failed to clear chat history: ${error}`);
    }
  }
}
