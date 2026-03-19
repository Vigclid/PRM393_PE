import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../interfaces/wrapper/ApiResponseWrapper";

export function authorize(roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const { role } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
      role: string;
    };
    if (!role || !roles.includes(role)) {
      return res.status(200).json(responseWrapper("error", "Unauthorized"));
    }
    next();
  };
}
