import { Router } from "express";
import productCommentRoute from "../../modules/product-comments/product-comment.routes";

const route = Router();
route.use("/comments", productCommentRoute);

export default route;
