import { NextFunction, Request, Response } from "express";
import { GenericController } from "../../core/controllers/base.controller";
import { INotification } from "./notification.model";
import { notificationService } from "./notification.service";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
export class notificationController extends GenericController<INotification> {
  private notificationService: notificationService;
  constructor(notificationService: notificationService) {
    super(notificationService);
    this.notificationService = notificationService;
  }

  getNotificationByUserId = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.notificationService.getNotificationsByUserId(id);
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  updateReadNotifications = async (req: Request, res: Response) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      await this.notificationService.setReadNotificationByUserId(id);
      return res.status(200).json(responseWrapper("success", "Notifications updated successfully"));
    } catch (error) {
      res.status(500).json(responseWrapper("error", "Internal Server Error"));
    }
  };
}
