import { IUser } from "./user.model";
import { GenericController } from "../../core/controllers/base.controller";
import { userService } from "./user.service";
import { NextFunction, Request, Response } from "express";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import jwt from "jsonwebtoken";
export class userController extends GenericController<IUser> {
  private UserService: userService;
  constructor(userService: userService) {
    super(userService);
    this.UserService = userService;
  }

  getAllPopulated = async (_req: Request, res: Response) => {
    res.json(
      responseWrapper("success", "Fetched successfully", await this.UserService.getAllPopulated())
    );
  };

  changePassword = async (req: Request, res: Response) => {
    try {
      const { password, oldPassword } = req.body;
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const checkPass = await this.UserService.checkPassword(id, oldPassword);
      if (!checkPass) return res.status(200).json(responseWrapper("error", "Wrong old password"));
      await this.UserService.changePassword(id, password);
      res.json(responseWrapper("success", "Change password successfully"));
    } catch (error) {
      res.status(404).json(responseWrapper("error", "Something wrongs!"));
    }
  };

  getTop10PopularUsers = async (_req: Request, res: Response) => {
    try {
      const users = await this.UserService.getTop10PopularUsers();
      res.json(responseWrapper("success", "Fetched top 10 popular users successfully", users));
    } catch (error) {
      console.error(error);
      res.status(500).json(responseWrapper("error", "Failed to fetch popular users"));
    }
  };

  checkExistEmail = async (req: Request, res: Response) => {
    try {
      const email = String(req.params.email || "").trim();
      if (!email) return res.status(400).json(responseWrapper("error", "Email is required"));
      const user = await this.UserService.getByEmail(email);
      return res
        .status(200)
        .json(responseWrapper("success", "Checked successfully", { exists: !!user }));
    } catch (error) {
      res.status(500).json(responseWrapper("error", "Internal Server Error"));
    }
  };

  resetPassword = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, password } = req.body;
      const token = await this.UserService.changePasswordByEmail(email, password);
      return res
        .status(200)
        .json(responseWrapper("success", "Password reset successfully", { token }));
    } catch (error) {
      next(error);
    }
  };

  lockAccount = async (req: Request, res: Response) => {
    try {
      const userId = String(req.params.id || "").trim();
      if (!userId) return res.status(400).json(responseWrapper("error", "User ID is required"));
      await this.UserService.lockAccount(userId);
      return res.status(200).json(responseWrapper("success", "Account locked successfully"));
    } catch (error) {
      res.status(500).json(responseWrapper("error", "Internal Server Error"));
    }
  };

  unlockAccount = async (req: Request, res: Response) => {
    try {
      const userId = String(req.params.id || "").trim();
      if (!userId) return res.status(400).json(responseWrapper("error", "User ID is required"));
      await this.UserService.unlockAccount(userId);
      return res.status(200).json(responseWrapper("success", "Account unlocked successfully"));
    } catch (error) {
      res.status(500).json(responseWrapper("error", "Internal Server Error"));
    }
  };
  getUserIsActive = async (_req: Request, res: Response) => {
    try {
      const user = await this.UserService.getUserIsActive();
      res.json(responseWrapper("success", "Get user successfully", user));
    } catch (error: any) {
      res.json(responseWrapper("error", "Get user fail", error));
    }
  };

  updateProfile = async (req: Request, res: Response) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const updatedUser = await this.UserService.updateProfile(id, req.body);

      if (!updatedUser) {
        return res.status(404).json(responseWrapper("error", "User not found"));
      }

      res.status(200).json(responseWrapper("success", "Profile updated successfully", updatedUser));
    } catch (error) {
      res.status(500).json(responseWrapper("error", "Internal Server Error", error));
    }
  };

  getNumberOfUsers = async (_req: Request, res: Response) => {
    try {
      const count = await this.UserService.getNumberOfUsers();
      res
        .status(200)
        .json(responseWrapper("success", "Fetched user count successfully", { count }));
    } catch (error) {
      res.status(500).json(responseWrapper("error", "Failed to fetch user count", error));
    }
  };
}
