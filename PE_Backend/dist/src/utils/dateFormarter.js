"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.vietNameDateNow = void 0;
const vietNameDateNow = () => {
    const now = new Date();
    now.setHours(now.getHours() + 7);
    return now;
};
exports.vietNameDateNow = vietNameDateNow;
