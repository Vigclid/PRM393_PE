import { Request, Response } from "express";
import { AuthService } from "./auth.service";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import ms from "ms";
import { userService } from "../users/user.service";
import jwt from "jsonwebtoken";
import { IGoogleUserInfo } from "./auth.model";
import { IUser } from "../users/user.model";

export class AuthController {
  static async login(req: Request, res: Response) {
    const { email, password } = req.body;

    const tokens = await AuthService.login(email, password);

    if (tokens.status === 0) {
      return res.status(200).json(responseWrapper("error", tokens.message || "Login failed"));
    }
    // set refreshToken on cookie HTTP-Only
    res.cookie("refreshToken", tokens.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: ms((process.env.JWT_REFRESH_EXPIRES_IN || "7d") as Parameters<typeof ms>[0]),
    });
    const { id } = jwt.decode(tokens.accessToken as string) as { id: string };

    await new userService().updateLastLogin(id);
    res.json(
      responseWrapper("success", "Login successful", {
        accessToken: tokens.accessToken,
        user: tokens.user,
      })
    );
  }

  static async refreshAccessToken(req: Request, res: Response) {
    try {
      const refreshTokenFromCookie = req.cookies?.refreshToken;
      const newAccessToken = AuthService.refresh(refreshTokenFromCookie);
      if (!newAccessToken) {
        return res.status(403).json(responseWrapper("error", "Invalid refresh token"));
      }
      res.json({ accessToken: newAccessToken });
    } catch (error) {
      return res.status(403).json(responseWrapper("error", "Invalid refresh token"));
    }
  }

  static loginWithGoogle = async (req: Request, res: Response) => {
    try {
      const users: IUser | null = await AuthService.loginWithGoogle(
        req.body.ggAccount as IGoogleUserInfo
      );
      if (!users) {
        return res.status(200).json(responseWrapper("error", "Login failed"));
      }
      if (users.isActive === false) {
        return res.status(200).json(responseWrapper("error", "Banned account"));
      }
      const tokens = AuthService.signByUser(users);
      res.cookie("refreshToken", tokens?.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
        maxAge: ms((process.env.JWT_REFRESH_EXPIRES_IN || "7d") as Parameters<typeof ms>[0]),
      });
      res.json(responseWrapper("success", "Login successful", tokens));
    } catch (error) {
      return res.status(500).json(responseWrapper("error", "Login failed"));
    }
  };

  static logout = (_req: Request, res: Response) => {
    try {
      res.clearCookie("refreshToken", {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
      });
      return res.status(200).json(responseWrapper("success", "Logout successful"));
    } catch (err) {
      return res.status(500).json(responseWrapper("error", "Logout failed"));
    }
  };
}
