import { GenericController } from "../../core/controllers/base.controller";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { IProduct } from "./product.model";
import { productService } from "./product.service";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { deleteImageByUrl, uploadImage } from "../../utils/imageUtils";
export class productController extends GenericController<IProduct> {
  private ProductService: productService;
  constructor(productService: productService) {
    super(productService);
    this.ProductService = productService;
  }

  createProductByMe = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      req.body.userId = id;
      req.body.imageUrl = (await uploadImage(req.body.image, 3, false)).image.secure_url;
      const response = await this.ProductService.create(req.body);
      res.json(responseWrapper("success", "Created successfully", response));
    } catch (error) {
      console.log(error);
      next(error);
    }
  };

  getProductPopulated = async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const response = await this.ProductService.getProductPopulated();
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  getMyProducts = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.ProductService.getMyProducts(id);
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  updateProduct = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const product = await this.ProductService.getById(req.params.id);
      if (product?.imageUrl !== req.body.image) {
        await deleteImageByUrl(product?.imageUrl as string);
        req.body.imageUrl = (await uploadImage(req.body.image, 3, false)).image.secure_url;
      }
      const response = await this.ProductService.update(req.params.id, req.body);
      res.json(responseWrapper("success", "Updated successfully", response));
    } catch (error) {
      next(error);
    }
  };

  deleteProduct = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const product = await this.ProductService.getById(req.params.id);
      if (product?.imageUrl) await deleteImageByUrl(product?.imageUrl as string);
      const response = await this.ProductService.delete(req.params.id);
      res.json(responseWrapper("success", "Deleted successfully", response));
    } catch (error) {
      next(error);
    }
  };

  getAllProductsWithAverageRating = async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const response = await this.ProductService.getAllProductsWithAverageRating();
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };
}
