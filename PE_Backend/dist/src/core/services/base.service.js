"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GenericService = void 0;
class GenericService {
    constructor(model) {
        this.model = model;
    }
    create(data) {
        return this.model.create(data);
    }
    createMany(data) {
        return this.model.insertMany(data);
    }
    getAll() {
        return this.model.find();
    }
    getById(id) {
        return this.model.findById(id);
    }
    update(id, data) {
        return this.model.findByIdAndUpdate(id, data, { new: true });
    }
    delete(id) {
        return this.model.findByIdAndDelete(id);
    }
    getByStatus() {
        return this.model.find({ status: 1 });
    }
}
exports.GenericService = GenericService;
