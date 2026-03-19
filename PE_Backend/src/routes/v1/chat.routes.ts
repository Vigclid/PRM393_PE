import { Router } from "express";
import chatRoute from "../../modules/chats/chat.routes";
const route = Router();
route.use("/chats", chatRoute);
export default route;
