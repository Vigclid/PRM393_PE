"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticate = authenticate;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const jwt_1 = require("../config/jwt");
const ApiResponseWrapper_1 = require("../interfaces/wrapper/ApiResponseWrapper");
function authenticate(req, res, next) {
    const token = req.headers["authorization"]?.split(" ")[1];
    if (!token)
        return res.status(401).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Token not found"));
    jsonwebtoken_1.default.verify(token, jwt_1.jwtConfig.secret, (err, decoded) => {
        if (err)
            return res.status(403).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Invalid token"));
        req.user = decoded;
        next();
    });
}
