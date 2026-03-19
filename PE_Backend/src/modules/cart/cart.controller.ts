import { GenericController } from "../../core/controllers/base.controller";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { ICart } from "./cart.model";
import { cartService } from "./cart.service";
export class cartController extends GenericController<ICart> {
  private CartService: cartService;
  constructor(productService: cartService) {
    super(productService);
    this.CartService = productService;
  }
  getByMe = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.CartService.getMyCartPopulated(id);
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  updateProductToMyCart = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.CartService.updateProductToMyCart(id, req.body);
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };
}
