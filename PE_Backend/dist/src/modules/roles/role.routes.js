"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const role_controller_1 = require("./role.controller");
const router = (0, express_1.Router)();
router.route("/").post(role_controller_1.roleController.create).get(role_controller_1.roleController.getAll);
router
    .route("/:id")
    .get(role_controller_1.roleController.getById)
    .put(role_controller_1.roleController.update)
    .delete(role_controller_1.roleController.delete);
exports.default = router;
