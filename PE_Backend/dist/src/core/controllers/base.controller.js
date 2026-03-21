"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericController = void 0;
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
class GenericController {
    constructor(service) {
        this.create = async (req, res, next) => {
            try {
                const result = await this.service.create(req.body);
                res.status(201).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Created successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.createMany = async (req, res, next) => {
            try {
                const result = await this.service.createMany(req.body);
                res.status(201).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Created successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.getAll = async (_req, res, next) => {
            try {
                const result = await this.service.getAll();
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.getById = async (req, res, next) => {
            try {
                const result = await this.service.getById(req.params.id);
                if (!result) {
                    return res.status(404).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Not found"));
                }
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.update = async (req, res, next) => {
            try {
                const result = await this.service.update(req.params.id, req.body);
                if (!result) {
                    return res.status(404).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Not found"));
                }
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Updated successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.delete = async (req, res, next) => {
            try {
                const result = await this.service.delete(req.params.id);
                if (!result) {
                    return res.status(404).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Not found"));
                }
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Deleted successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.getByStatus = async (_req, res, next) => {
            try {
                const result = await this.service.getByStatus();
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", result));
            }
            catch (error) {
                next(error);
            }
        };
        this.service = service;
    }
}
exports.GenericController = GenericController;
