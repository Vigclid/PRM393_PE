"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationService = void 0;
const base_service_1 = require("../../core/services/base.service");
const notification_model_1 = __importDefault(require("./notification.model"));
class notificationService extends base_service_1.GenericService {
    constructor() {
        super(notification_model_1.default);
        this.getNotificationsByUserId = async (userId) => {
            try {
                const response = await notification_model_1.default
                    .find({ profileReceiveId: userId })
                    .populate("profileNotifyId");
                return response;
            }
            catch (err) { }
        };
        this.setReadNotificationByUserId = async (userId) => {
            try {
                await notification_model_1.default.updateMany({ profileReceiveId: userId }, { isRead: 1 });
            }
            catch (err) { }
        };
        this.createNotificationFromFollow = async (data) => {
            try {
                return await (await notification_model_1.default.create({
                    followId: data._id,
                    message: `#3 You have new follower!`,
                    createAt: new Date(),
                    profileNotifyId: data.followerId,
                    profileReceiveId: data.followingId,
                    isRead: false,
                })).populate("profileNotifyId");
            }
            catch (err) { }
        };
    }
}
exports.notificationService = notificationService;
