import { Router } from "express";
import messageRoute from "../../modules/messages/message.routes";
const route = Router();
route.use("/messages", messageRoute);
export default route;
