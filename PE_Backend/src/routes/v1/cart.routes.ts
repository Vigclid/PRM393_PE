import { Router } from "express";
import cartRoute from "../../modules/cart/cart.routes";
const route = Router();
route.use("/carts", cartRoute);
export default route;
