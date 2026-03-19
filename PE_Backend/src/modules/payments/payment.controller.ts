import { paymentService } from "./payment.service";
import { userService } from "../users/user.service";
import { IPayment, IQrInformation } from "./payment.model";
import { GenericController } from "../../core/controllers/base.controller";
import { Request, Response } from "express";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import jwt from "jsonwebtoken";
import axios from "axios";
import crypto from "crypto";
import QRCode from "qrcode";

export class PaymentController extends GenericController<IPayment> {
  private PaymentService: paymentService;
  constructor(paymentService: paymentService) {
    super(paymentService);
    this.PaymentService = paymentService;
  }

  getQrCode = async (req: Request, res: Response) => {
    const IQrInfor: IQrInformation = req.body;
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const deposite = 25000;
      const orderCode = Number(Date.now().toString().slice(4, 9).concat(IQrInfor.description));
      const cancelUrl = "https://example.com/payment/cancel";
      const returnUrl = "https://example.com/payment/success";

      const dataToSign = `amount=${IQrInfor.amount}&cancelUrl=${cancelUrl}&description=${IQrInfor.description}&orderCode=${orderCode}&returnUrl=${returnUrl}`;
      const signature = crypto
        .createHmac("sha256", process.env.PAYOS_CHECKSUM_KEY as string)
        .update(dataToSign)
        .digest("hex");
      const response = await axios.post(
        "https://api-merchant.payos.vn/v2/payment-requests",
        {
          orderCode,
          amount: IQrInfor.amount,
          description: IQrInfor.description,
          cancelUrl,
          returnUrl,
          signature,
        },
        {
          headers: {
            "x-client-id": process.env.PAYOS_CLIENT_ID,
            "x-api-key": process.env.PAYOS_API_KEY,
            "Content-Type": "application/json",
          },
        }
      );

      if (response.data.data == null) {
        return res.status(500).json(responseWrapper("error", "Server error", response.data));
      } else {
        await this.PaymentService.create({
          userId: id,
          orderCode,
          amount: IQrInfor.amount / deposite,
          status: false,
        });
        const qrCodeDataURL = await QRCode.toDataURL(response.data.data.qrCode);
        response.data.data.qrCode = qrCodeDataURL;
        return res.status(200).json(responseWrapper("success", "Success", response.data.data));
      }
    } catch (err) {
      return res.status(500).json(responseWrapper("error", "Server error"));
    }
  };
  acceptPayment = async (req: Request, res: Response) => {
    try {
      const { orderCode } = req.body;
      if (!orderCode) return res.status(400).json({ message: "Missing orderCode" });

      const response = await axios.get(
        `https://api-merchant.payos.vn/v2/payment-requests/${orderCode}`,
        {
          headers: {
            "x-client-id": process.env.PAYOS_CLIENT_ID,
            "x-api-key": process.env.PAYOS_API_KEY,
          },
        }
      );
      if (response.data.data.status === "PAID") {
        const payment = (await this.PaymentService.acceptPayment(
          Number(orderCode)
        )) as Partial<IPayment>;
        await new userService().updateCoinForPayment(payment.userId, payment.amount!);
        return res.status(200).json({ status: "success", message: "Payment accepted" });
      } else {
        return res.status(200).json({ status: "pending", message: "Payment pending" });
      }
    } catch (error) {
      res.status(500).json({ message: "Error checking order" });
    }
  };
}
