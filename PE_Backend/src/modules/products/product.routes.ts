import { Router } from "express";
import { productController } from "./product.controller";
import { productService } from "./product.service";
import { authenticate } from "../../middlewares/authMiddleware";

const router = Router();
const ProductController = new productController(new productService());

router.route("/").post(ProductController.create).get(ProductController.getAllProductsWithAverageRating);
router
  .route("/me")
  .post(authenticate, ProductController.createProductByMe)
  .get(authenticate, ProductController.getMyProducts);
router.route("/populated").get(ProductController.getProductPopulated);
router
  .route("/:id")
  .put(authenticate, ProductController.updateProduct)
  .delete(authenticate, ProductController.deleteProduct);
// SELF CHAT
export default router;
