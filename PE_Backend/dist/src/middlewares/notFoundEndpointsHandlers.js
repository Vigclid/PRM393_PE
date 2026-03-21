"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundEndpointsHandler = notFoundEndpointsHandler;
function notFoundEndpointsHandler(req, res) {
    res.status(404).json({
        message: `Endpoint ${req.method} ${req.originalUrl} not found`,
    });
}
