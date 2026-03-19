import { Request, Response } from "express";
import { responseWrapper } from "../interfaces/wrapper/ApiResponseWrapper";

const errorHandler = (err: any, _req: Request, res: Response) => {
  res.status(500).json(responseWrapper("error", err.message));
};

export default errorHandler;
