import { Router } from "express";
import productRoute from "../../modules/products/product.routes";
const route = Router();
route.use("/products", productRoute);
export default route;
