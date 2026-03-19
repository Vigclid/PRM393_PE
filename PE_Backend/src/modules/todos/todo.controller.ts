import { NextFunction, Request, Response } from "express";
import { GenericController } from "../../core/controllers/base.controller";
import jwt from "jsonwebtoken";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";
import { ITodo } from "./todo.model";
import { todoService } from "./todo.service";
export class todoController extends GenericController<ITodo> {
  private todoService: todoService;
  constructor(todoService: todoService) {
    super(todoService);
    this.todoService = todoService;
  }

  getMyTodos = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      const response = await this.todoService.getMyTodos(id);
      res.json(responseWrapper("success", "Fetched successfully", response));
    } catch (error) {
      next(error);
    }
  };

  createByMe = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = jwt.decode(req.headers["authorization"]?.split(" ")[1] as string) as {
        id: string;
      };
      req.body.userId = id;
      const response = await this.todoService.create(req.body);
      res.json(responseWrapper("success", "Created successfully", response));
    } catch (error) {
      next(error);
    }
  };

  toggleMyTodos = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const id = req.params.id as string;
      const response = await this.todoService.toggleMyTodos(id);
      res.json(responseWrapper("success", "Toggled successfully", response));
    } catch (error) {
      next(error);
    }
  };
}
