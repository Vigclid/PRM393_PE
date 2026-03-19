import { GenericService } from "../../core/services/base.service";
import { IFollow } from "../follow/follow.model";
import notificationModel, { INotification } from "./notification.model";

export class notificationService extends GenericService<INotification> {
  constructor() {
    super(notificationModel);
  }

  getNotificationsByUserId = async (userId: string) => {
    try {
      const response = await notificationModel
        .find({ profileReceiveId: userId })
        .populate("profileNotifyId");
      return response;
    } catch (err: any) {}
  };

  setReadNotificationByUserId = async (userId: string) => {
    try {
      await notificationModel.updateMany({ profileReceiveId: userId }, { isRead: 1 });
    } catch (err: any) {}
  };

  createNotificationFromFollow = async (data: IFollow) => {
    try {
      return await (
        await notificationModel.create({
          followId: data._id,
          message: `#3 You have new follower!`,
          createAt: new Date(),
          profileNotifyId: data.followerId,
          profileReceiveId: data.followingId,
          isRead: false,
        })
      ).populate("profileNotifyId");
    } catch (err: any) {}
  };
}
