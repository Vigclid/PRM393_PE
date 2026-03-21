"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.userService = void 0;
const base_service_1 = require("../../core/services/base.service");
const user_model_1 = __importDefault(require("./user.model"));
const role_model_1 = __importDefault(require("../roles/role.model"));
const bcryptjs_1 = __importDefault(require("bcryptjs"));
class userService extends base_service_1.GenericService {
    constructor() {
        super(user_model_1.default);
        this.getAllPopulated = async () => {
            return user_model_1.default.find().populate("roleID").exec();
        };
        this.create = async (data) => {
            const role = await role_model_1.default.findOne({ name: "User" });
            if (!role) {
                throw new Error("Role 'user' not found");
            }
            const newUser = new user_model_1.default({
                ...data,
                roleID: role._id,
                password: bcryptjs_1.default.hashSync(String(data.password), 8),
            });
            return (await user_model_1.default.create(newUser)).populate("roleID");
        };
        this.getByEmail = async (email) => {
            return user_model_1.default.findOne({ email }).populate("roleID").exec();
        };
        this.updateLastLogin = async (id) => {
            return user_model_1.default.findByIdAndUpdate(id, { lastLogin: new Date() }, { new: true });
        };
        this.changePassword = async (id, password) => {
            return user_model_1.default.findByIdAndUpdate(id, { password: bcryptjs_1.default.hashSync(password, 8) }, { new: true });
        };
        this.changePasswordByEmail = async (email, password) => {
            return user_model_1.default.findOneAndUpdate({ email }, { password: bcryptjs_1.default.hashSync(password, 8) }, { new: true });
        };
        this.checkPassword = async (id, password) => {
            const user = await this.getById(id);
            if (!user)
                return false;
            return bcryptjs_1.default.compareSync(password, user.password);
        };
        this.getTop10PopularUsers = async () => {
            const users = await user_model_1.default.aggregate([
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
        this.lockAccount = async (id) => {
            return user_model_1.default.findByIdAndUpdate(id, { isActive: false }, { new: true });
        };
        this.unlockAccount = async (id) => {
            return user_model_1.default.findByIdAndUpdate(id, { isActive: true }, { new: false });
        };
        this.updateProfile = async (id, data) => {
            const { firstName, lastName, address, dateOfBirth, phoneNumber, biography } = data;
            return user_model_1.default
                .findByIdAndUpdate(id, { firstName, lastName, address, dateOfBirth, phoneNumber, biography }, { new: true })
                .populate("roleID");
        };
        this.updateCoinByUserId = async (userID, amount) => {
            return await user_model_1.default.findOneAndUpdate({ _id: userID }, { $set: { coins: amount } }, { new: true });
        };
        this.getUserIsActive = async () => {
            try {
                const listArtwork = await user_model_1.default.find({ isActive: true });
                return listArtwork;
            }
            catch (error) {
                throw new Error(`fail to get List artwork by tag: ${error.message}`);
            }
        };
        this.updateCoinForPayment = async (userID, amount) => {
            const currentUser = await this.getById(userID);
            const currentCoins = parseFloat(currentUser?.coins);
            console.log("Current Coins:", currentCoins);
            const coin = currentCoins + amount;
            return await user_model_1.default.findOneAndUpdate({ _id: userID }, { $set: { coins: coin } }, { new: true });
        };
        this.getNumberOfUsers = async () => {
            try {
                const count = await user_model_1.default.countDocuments();
                return count;
            }
            catch (error) {
                throw new Error(`Failed to get number of users: ${error.message}`);
            }
        };
    }
}
exports.userService = userService;
