import { Router } from "express";
import { cartController } from "./cart.controller";
import { cartService } from "./cart.service";
import { authenticate } from "../../middlewares/authMiddleware";

const router = Router();
const CartController = new cartController(new cartService());

router.route("/").post(CartController.create).get(CartController.getAll);
router
  .route("/me")
  .get(authenticate, CartController.getByMe)
  .post(authenticate, CartController.updateProductToMyCart);
export default router;
