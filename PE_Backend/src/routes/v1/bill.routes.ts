import { Router } from "express";
import billRoute from "../../modules/bills/bill.routes";
const route = Router();
route.use("/bills", billRoute);
export default route;
