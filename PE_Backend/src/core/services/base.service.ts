import { Model, Document } from "mongoose";

export class GenericService<T extends Document> {
  private model: Model<T>;

  constructor(model: Model<T>) {
    this.model = model;
  }

  create(data: Partial<T>) {
    return this.model.create(data);
  }

  createMany(data: Partial<T>[]) {
    return this.model.insertMany(data);
  }

  getAll() {
    return this.model.find();
  }

  getById(id: string) {
    return this.model.findById(id);
  }

  update(id: string, data: Partial<T>) {
    return this.model.findByIdAndUpdate(id, data, { new: true });
  }

  delete(id: string) {
    return this.model.findByIdAndDelete(id);
  }

  getByStatus() {
    return this.model.find({ status: 1 });
  }
}
