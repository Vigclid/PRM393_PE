import { Request, Response } from "express";
export function notFoundEndpointsHandler(req: Request, res: Response) {
  res.status(404).json({
    message: `Endpoint ${req.method} ${req.originalUrl} not found`,
  });
}
