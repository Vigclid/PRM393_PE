import { Types } from "mongoose";
import { GenericService } from "../../core/services/base.service";
import cartModel, { ICart, ICartItem } from "./cart.model";

export class cartService extends GenericService<ICart> {
  constructor() {
    super(cartModel);
  }

  getMyCartPopulated = async (_id: string) => {
    return cartModel.findOne({ userId: _id }).populate("items.productId");
  };

  updateProductToMyCart = async (userId: string, data: Partial<ICartItem>) => {
    const cart = await cartModel.findOne({ userId });

    if (!cart) {
      const cartItem: ICartItem = {
        productId: data.productId as Types.ObjectId,
        quantity: 1,
        priceAtTime: data.priceAtTime as number,
      };
      return await cartModel.create({ userId, items: [cartItem] });
    }

    const existingItem = cart.items.find(
      (item) => item.productId.toString() === (data.productId as Types.ObjectId).toString()
    );

    if (existingItem) {
      if (data.quantity === 0) {
        cart.items = cart.items.filter(
          (item) => item.productId.toString() !== (data.productId as Types.ObjectId).toString()
        );
      } else {
        existingItem.quantity = data.quantity!;
      }
    } else {
      cart.items.push({
        productId: data.productId as Types.ObjectId,
        quantity: 1,
        priceAtTime: data.priceAtTime as number,
      });
    }
    await cart.save();
    return cart;
  };
}
