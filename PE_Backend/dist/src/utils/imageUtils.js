"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadImage = uploadImage;
exports.generateSignedUrl = generateSignedUrl;
exports.base64 = base64;
exports.deleteImageByUrl = deleteImageByUrl;
const cloudinary = require("cloudinary").v2;
const uuid_1 = require("uuid"); // ✅ static import
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
});
const FOLDER_MAP = {
    "1": "avatar",
    "2": "background",
    "3": "Products",
};
async function uploadImage(base64, type, isBuy) {
    const folderName = FOLDER_MAP[String(type)];
    if (!folderName)
        throw new Error("Invalid type");
    const uniqueFileName = (0, uuid_1.v4)();
    if (type === 1 || type === 2) {
        return await cloudinary.uploader.upload(base64, {
            folder: folderName,
            public_id: uniqueFileName,
            overwrite: true,
            resource_type: "image",
        });
    }
    if (type === 3) {
        const image = await cloudinary.uploader.upload(base64, {
            folder: "Products",
            public_id: uniqueFileName,
            overwrite: true,
            resource_type: "image",
        });
        let preview = "";
        if (isBuy) {
            // Ảnh preview (có watermark)
            let preImage = await cloudinary.uploader.upload(base64, {
                folder: "previews",
                public_id: uniqueFileName,
                overwrite: true,
                resource_type: "image",
                transformation: [
                    {
                        overlay: "arthub",
                        gravity: "center",
                        flags: "relative",
                        width: 0.3,
                        opacity: 60,
                        crop: "scale",
                    },
                ],
            });
            preview = preImage;
        }
        return { image, preview };
    }
}
function generateSignedUrl(publicId) {
    return cloudinary.utils.private_download_url(publicId, "jpg", {
        type: "private",
        expires_at: Math.floor(Date.now() / 1000) + 60,
    });
}
function base64(filePath) {
    let base64;
    if (filePath === null || filePath === "") {
        throw new Error("File path is empty");
    }
    else {
        base64 = `data:image/jpeg;base64${Buffer.from(filePath).toString("base64")}`;
        return base64;
    }
}
async function deleteImageByUrl(url) {
    try {
        if (!url)
            return;
        const parts = url.split("/");
        const lastPart = parts[parts.length - 1];
        const publicId = lastPart.split(".")[0];
        const folder = parts.includes("Products") ? "Products" : "";
        const fullPublicId = folder ? `${folder}/${publicId}` : publicId;
        const result = await cloudinary.uploader.destroy(fullPublicId);
        return result;
    }
    catch (err) {
        console.error("Delete image error:", err);
        throw err;
    }
}
