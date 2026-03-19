import { Router } from "express";
import mailRoute from "../../modules/mail/mail.routes";
const route = Router();

route.use("/mail", mailRoute);
export default route;
