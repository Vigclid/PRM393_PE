"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authorize = authorize;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../interfaces/wrapper/ApiResponseWrapper");
function authorize(roles) {
    return (req, res, next) => {
        const { role } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
        if (!role || !roles.includes(role)) {
            return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Unauthorized"));
        }
        next();
    };
}
