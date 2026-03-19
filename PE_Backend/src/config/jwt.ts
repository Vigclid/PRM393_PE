export const jwtConfig = {
  secret: process.env.JWT_SECRET || "super-secret-key",
  expiresIn: process.env.JWT_EXPIRES_IN || "1h",
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d",
};
