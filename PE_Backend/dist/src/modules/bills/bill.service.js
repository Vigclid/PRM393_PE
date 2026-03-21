"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.billService = void 0;
const base_service_1 = require("../../core/services/base.service");
const bill_model_1 = __importDefault(require("./bill.model"));
class billService extends base_service_1.GenericService {
    constructor() {
        super(bill_model_1.default);
        this.checkout = async (userId, cart) => {
            if (!cart || cart.items.length === 0) {
                throw new Error("Giỏ hàng trống");
            }
            const bill = await bill_model_1.default.create({
                userId,
                items: cart.items,
            });
            return bill;
        };
        this.getRevenueStatistics = async (filterType = "day") => {
            let groupFormat = "%Y-%m-%d";
            if (filterType === "month")
                groupFormat = "%Y-%m";
            if (filterType === "year")
                groupFormat = "%Y";
            const stats = await bill_model_1.default.aggregate([
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
}
exports.billService = billService;
