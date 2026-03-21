"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const auth_service_1 = require("./auth.service");
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const ms_1 = __importDefault(require("ms"));
const user_service_1 = require("../users/user.service");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
class AuthController {
    static async login(req, res) {
        const { email, password } = req.body;
        const tokens = await auth_service_1.AuthService.login(email, password);
        if (tokens.status === 0) {
            return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("error", tokens.message || "Login failed"));
        }
        // set refreshToken on cookie HTTP-Only
        res.cookie("refreshToken", tokens.refreshToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === "production",
            sameSite: "strict",
            maxAge: (0, ms_1.default)((process.env.JWT_REFRESH_EXPIRES_IN || "7d")),
        });
        const { id } = jsonwebtoken_1.default.decode(tokens.accessToken);
        await new user_service_1.userService().updateLastLogin(id);
        res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Login successful", {
            accessToken: tokens.accessToken,
            user: tokens.user,
        }));
    }
    static async refreshAccessToken(req, res) {
        try {
            const refreshTokenFromCookie = req.cookies?.refreshToken;
            const newAccessToken = auth_service_1.AuthService.refresh(refreshTokenFromCookie);
            if (!newAccessToken) {
                return res.status(403).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Invalid refresh token"));
            }
            res.json({ accessToken: newAccessToken });
        }
        catch (error) {
            return res.status(403).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Invalid refresh token"));
        }
    }
}
exports.AuthController = AuthController;
_a = AuthController;
AuthController.loginWithGoogle = async (req, res) => {
    try {
        const users = await auth_service_1.AuthService.loginWithGoogle(req.body.ggAccount);
        if (!users) {
            return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Login failed"));
        }
        if (users.isActive === false) {
            return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Banned account"));
        }
        const tokens = auth_service_1.AuthService.signByUser(users);
        res.cookie("refreshToken", tokens?.refreshToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === "production",
            sameSite: "strict",
            maxAge: (0, ms_1.default)((process.env.JWT_REFRESH_EXPIRES_IN || "7d")),
        });
        res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Login successful", tokens));
    }
    catch (error) {
        return res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Login failed"));
    }
};
AuthController.logout = (_req, res) => {
    try {
        res.clearCookie("refreshToken", {
            httpOnly: true,
            secure: process.env.NODE_ENV === "production",
            sameSite: "strict",
        });
        return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Logout successful"));
    }
    catch (err) {
        return res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Logout failed"));
    }
};
