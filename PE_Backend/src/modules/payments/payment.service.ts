import { GenericService } from "../../core/services/base.service";
import paymentModel, { IPayment } from "./payment.model";

export class paymentService extends GenericService<IPayment> {
  constructor() {
    super(paymentModel);
  }

  purchaseCoins = async (data: Partial<IPayment>) => {
    return await paymentModel.create(data);
  };

  acceptPayment = async (orderCode: number) => {
    return await paymentModel.findOneAndUpdate(
      { orderCode },
      { $set: { status: true } },
      { new: true }
    );
  };
}
