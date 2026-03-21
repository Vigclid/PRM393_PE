"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.responseWrapper = void 0;
const responseWrapper = (status, message, data, error_log) => {
    return {
        status,
        message,
        data,
        error_log,
        timestamp: new Date().toISOString(),
    };
};
exports.responseWrapper = responseWrapper;
