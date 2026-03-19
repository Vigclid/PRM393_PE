import { GenericService } from "../../core/services/base.service";
import userModel, { IUser } from "./user.model";
import roleModel from "../roles/role.model";
import bcrypt from "bcryptjs";

export class userService extends GenericService<IUser> {
  constructor() {
    super(userModel);
  }
  getAllPopulated = async () => {
    return userModel.find().populate("roleID").exec();
  };

  create = async (data: Partial<IUser>) => {
    const role = await roleModel.findOne({ name: "User" });
    if (!role) {
      throw new Error("Role 'user' not found");
    }

    const newUser = new userModel({
      ...data,
      roleID: role._id,
      password: bcrypt.hashSync(String(data.password), 8),
    });

    return (await userModel.create(newUser)).populate("roleID");
  };

  getByEmail = async (email: string) => {
    return userModel.findOne({ email }).populate("roleID").exec();
  };

  updateLastLogin = async (id: string) => {
    return userModel.findByIdAndUpdate(id, { lastLogin: new Date() }, { new: true });
  };

  changePassword = async (id: string, password: string) => {
    return userModel.findByIdAndUpdate(
      id,
      { password: bcrypt.hashSync(password, 8) },
      { new: true }
    );
  };

  changePasswordByEmail = async (email: string, password: string) => {
    return userModel.findOneAndUpdate(
      { email },
      { password: bcrypt.hashSync(password, 8) },
      { new: true }
    );
  };
  checkPassword = async (id: string, password: string) => {
    const user = await this.getById(id);
    if (!user) return false;
    return bcrypt.compareSync(password, user.password);
  };

  getTop10PopularUsers = async () => {
    const users = await userModel.aggregate([
      {
        $lookup: {
          from: "artworks",
          localField: "_id",
          foreignField: "userID",
          as: "artworks",
        },
      },
      {
        $addFields: {
          totalLikes: { $sum: "$artworks.likes" },
          popularity: {
            $add: [
              { $multiply: ["$followerCount", 0.5] },
              { $multiply: [{ $sum: "$artworks.likes" }, 0.75] },
            ],
          },
        },
      },
      { $sort: { popularity: -1 } },
      { $limit: 10 },
    ]);

    return users;
  };

  lockAccount = async (id: string) => {
    return userModel.findByIdAndUpdate(id, { isActive: false }, { new: true });
  };

  unlockAccount = async (id: string) => {
    return userModel.findByIdAndUpdate(id, { isActive: true }, { new: false });
  };

  updateProfile = async (id: string, data: Partial<IUser>) => {
    const { firstName, lastName, address, dateOfBirth, phoneNumber, biography } = data;

    return userModel
      .findByIdAndUpdate(
        id,
        { firstName, lastName, address, dateOfBirth, phoneNumber, biography },
        { new: true }
      )
      .populate("roleID");
  };

  updateCoinByUserId = async (userID: any, amount: number) => {
    return await userModel.findOneAndUpdate(
      { _id: userID },
      { $set: { coins: amount } },
      { new: true }
    );
  };
  getUserIsActive = async () => {
    try {
      const listArtwork = await userModel.find({ isActive: true });
      return listArtwork;
    } catch (error: any) {
      throw new Error(`fail to get List artwork by tag: ${error.message}`);
    }
  };
  updateCoinForPayment = async (userID: any, amount: number) => {
    const currentUser = await this.getById(userID);
    const currentCoins = parseFloat(currentUser?.coins as string);
    console.log("Current Coins:", currentCoins);
    const coin = currentCoins + amount;
    return await userModel.findOneAndUpdate(
      { _id: userID },
      { $set: { coins: coin } },
      { new: true }
    );
  };

  getNumberOfUsers = async (): Promise<number> => {
    try {
      const count = await userModel.countDocuments();
      return count;
    } catch (error: any) {
      throw new Error(`Failed to get number of users: ${error.message}`);
    }
  };
}
