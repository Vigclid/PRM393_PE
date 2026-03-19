import { GenericService } from "../../core/services/base.service";
import { ICart } from "../cart/cart.model";
import billModel, { IBill } from "./bill.model";

export class billService extends GenericService<IBill> {
  constructor() {
    super(billModel);
  }

  checkout = async (userId: string, cart: ICart) => {
    if (!cart || cart.items.length === 0) {
      throw new Error("Giỏ hàng trống");
    }
    const bill = await billModel.create({
      userId,
      items: cart.items,
    });
    return bill;
  };

  getRevenueStatistics = async (filterType: "day" | "month" | "year" = "day") => {
    let groupFormat = "%Y-%m-%d";
    if (filterType === "month") groupFormat = "%Y-%m";
    if (filterType === "year") groupFormat = "%Y";
    const stats = await billModel.aggregate([
      {
        $group: {
          _id: { $dateToString: { format: groupFormat, date: "$createdAt" } },
          totalRevenue: { $sum: "$totalPrice" },
          totalOrders: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);
    const totalRevenue = stats.reduce((sum, item) => sum + item.totalRevenue, 0);
    return {
      totalRevenue,
      breakdown: stats,
    };
  };
}
