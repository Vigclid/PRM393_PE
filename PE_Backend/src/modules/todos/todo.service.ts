import { GenericService } from "../../core/services/base.service";
import todoModel, { ITodo } from "./todo.model";

export class todoService extends GenericService<ITodo> {
  constructor() {
    super(todoModel);
  }

  getMyTodos = async (id: string) => {
    return todoModel.find({ userId: id });
  };

  toggleMyTodos = async (id: string) => {
    return todoModel
      .findById(id)
      .then((doc) => {
        if (doc) {
          doc.done = !doc.done;
          return doc.save();
        } else {
          throw new Error("Document not found");
        }
      })
      .catch((error) => {
        console.error(error);
        return null;
      });
  };
}
