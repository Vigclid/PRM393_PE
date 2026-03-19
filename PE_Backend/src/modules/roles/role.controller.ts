import roleModel, { IRole } from "./role.model";
import { GenericService } from "../../core/services/base.service";
import { GenericController } from "../../core/controllers/base.controller";

const roleService = new GenericService<IRole>(roleModel);
export const roleController = new GenericController<IRole>(roleService);
