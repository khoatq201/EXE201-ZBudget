import { v2 as cloudinary } from "cloudinary";
import { config } from "dotenv";

// Load environment variables
config();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Upload image to Cloudinary
 * @param {Buffer|string} file - File buffer or file path
 * @param {Object} options - Upload options
 * @returns {Promise<Object>} Upload result
 */
export const uploadImage = async (file, options = {}) => {
  try {
    const defaultOptions = {
      folder: "zbudget/avatars", // Organize uploads in folders
      transformation: [
        { width: 400, height: 400, crop: "fill" }, // Resize to 400x400
        { quality: "auto" }, // Auto optimize quality
        { format: "auto" }, // Auto choose best format (webp, etc.)
      ],
      ...options,
    };

    let uploadResult;

    if (Buffer.isBuffer(file)) {
      // Upload from buffer
      uploadResult = await new Promise((resolve, reject) => {
        cloudinary.uploader
          .upload_stream(defaultOptions, (error, result) => {
            if (error) reject(error);
            else resolve(result);
          })
          .end(file);
      });
    } else {
      // Upload from file path
      uploadResult = await cloudinary.uploader.upload(file, defaultOptions);
    }

    return {
      success: true,
      url: uploadResult.secure_url,
      publicId: uploadResult.public_id,
      width: uploadResult.width,
      height: uploadResult.height,
      format: uploadResult.format,
      bytes: uploadResult.bytes,
    };
  } catch (error) {
    console.error("Cloudinary upload error:", error);
    return {
      success: false,
      error: error.message,
    };
  }
};

/**
 * Delete image from Cloudinary
 * @param {string} publicId - Public ID of the image to delete
 * @returns {Promise<Object>} Delete result
 */
export const deleteImage = async (publicId) => {
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    return {
      success: result.result === "ok",
      result: result.result,
    };
  } catch (error) {
    console.error("Cloudinary delete error:", error);
    return {
      success: false,
      error: error.message,
    };
  }
};

/**
 * Generate transformation URL
 * @param {string} publicId - Public ID of the image
 * @param {Object} transformations - Transformation options
 * @returns {string} Transformed image URL
 */
export const getTransformedUrl = (publicId, transformations = {}) => {
  return cloudinary.url(publicId, {
    transformation: [
      { quality: "auto" },
      { format: "auto" },
      ...transformations,
    ],
  });
};

export default cloudinary;
