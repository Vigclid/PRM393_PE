"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const roleMiddleware_1 = require("../../middlewares/roleMiddleware");
const user_controller_1 = require("./user.controller");
const user_service_1 = require("./user.service");
const router = (0, express_1.Router)();
const UserController = new user_controller_1.userController(new user_service_1.userService());
router.route("/").post(UserController.create).get(UserController.getAll);
router.route("/populated").get(UserController.getAllPopulated);
router.route("/top10").get(UserController.getTop10PopularUsers);
router.route("/search").get(authMiddleware_1.authenticate, UserController.getUserIsActive);
router.route("/me/password").put(authMiddleware_1.authenticate, UserController.changePassword);
router.route("/me/password/reset").post(UserController.resetPassword);
router.route("/me/profile").put(UserController.updateProfile);
// ---------- ADMIN ----------
router.route("/count").get(authMiddleware_1.authenticate, (0, roleMiddleware_1.authorize)(["Admin"]), UserController.getNumberOfUsers);
router
    .route("/:id")
    .get(UserController.getById)
    .put(authMiddleware_1.authenticate, UserController.update)
    .delete(authMiddleware_1.authenticate, (0, roleMiddleware_1.authorize)(["Admin"]), UserController.delete);
router.route("/exist/:email").get(UserController.checkExistEmail);
router.route("/:id/lock").put(authMiddleware_1.authenticate, (0, roleMiddleware_1.authorize)(["Admin"]), UserController.lockAccount);
router.route("/:id/unlock").put(authMiddleware_1.authenticate, (0, roleMiddleware_1.authorize)(["Admin"]), UserController.unlockAccount);
// SELF CHAT
exports.default = router;
