import { GenericService } from "../../core/services/base.service";
import notificationModel, { INotification } from "./notification.model";
import { sendToUser } from "../../sockets/clientManager";

export class notificationService extends GenericService<INotification> {
  constructor() {
    super(notificationModel);
  }

  getNotificationsByUserId = async (userId: string) => {
    try {
      return await notificationModel
        .find({ profileReceiveId: userId })
        .populate("profileNotifyId", "email firstName lastName profilePicture")
        .sort({ createAt: -1 });
    } catch (err: any) {}
  };

  setReadNotificationByUserId = async (userId: string) => {
    try {
      await notificationModel.updateMany({ profileReceiveId: userId }, { isRead: 1 });
    } catch (err: any) {}
  };

  createPostCommentNotification = async (postAuthorId: string, actorId: string, postId: string) => {
    try {
      if (postAuthorId === actorId) return;
      const notification = await notificationModel.create({
        type: "comment",
        postId,
        message: "commented on your post",
        createAt: new Date(),
        profileNotifyId: actorId,
        profileReceiveId: postAuthorId,
        isRead: 0,
      });
      const populated = await notification.populate(
        "profileNotifyId",
        "email firstName lastName profilePicture"
      );
      sendToUser(postAuthorId, { type: "NOTIFICATION", notification: populated });
    } catch (err: any) {}
  };

  createPostReactionNotification = async (
    postAuthorId: string,
    actorId: string,
    postId: string,
    reactionType: string
  ) => {
    try {
      if (postAuthorId === actorId) return;
      const notification = await notificationModel.create({
        type: "postReaction",
        postId,
        message: `reacted to your post with ${reactionType}`,
        createAt: new Date(),
        profileNotifyId: actorId,
        profileReceiveId: postAuthorId,
        isRead: 0,
      });
      const populated = await notification.populate(
        "profileNotifyId",
        "email firstName lastName profilePicture"
      );
      sendToUser(postAuthorId, { type: "NOTIFICATION", notification: populated });
    } catch (err: any) {}
  };

  createCommentReactionNotification = async (
    commentAuthorId: string,
    actorId: string,
    postId: string,
    reactionType: string
  ) => {
    try {
      if (commentAuthorId === actorId) return;
      const notification = await notificationModel.create({
        type: "commentReaction",
        postId,
        message: `reacted to your comment with ${reactionType}`,
        createAt: new Date(),
        profileNotifyId: actorId,
        profileReceiveId: commentAuthorId,
        isRead: 0,
      });
      const populated = await notification.populate(
        "profileNotifyId",
        "email firstName lastName profilePicture"
      );
      sendToUser(commentAuthorId, { type: "NOTIFICATION", notification: populated });
    } catch (err: any) {}
  };
}
