"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const ApiResponseWrapper_1 = require("../interfaces/wrapper/ApiResponseWrapper");
const errorHandler = (err, _req, res) => {
    res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", err.message));
};
exports.default = errorHandler;
