"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv").config();
const express_1 = __importDefault(require("express"));
const errorHandlers_1 = __importDefault(require("./src/middlewares/errorHandlers"));
const index_routes_1 = __importDefault(require("./src/routes/index.routes"));
const notFoundEndpointsHandlers_1 = require("./src/middlewares/notFoundEndpointsHandlers");
const cors_1 = __importDefault(require("cors"));
const loggerMiddleware_1 = __importDefault(require("./src/middlewares/loggerMiddleware"));
const cookie_parser_1 = __importDefault(require("cookie-parser"));
const db_1 = require("./src/config/db");
const sockets_1 = require("./src/sockets");
const http_1 = __importDefault(require("http"));
const app = (0, express_1.default)();
app.use(express_1.default.json({ limit: "4mb" }));
app.use(express_1.default.urlencoded({ limit: "4mb", extended: true }));
app.use((0, cookie_parser_1.default)());
// CORS
const isProduction = process.env.NODE_ENV === "production";
const origin = isProduction ? process.env.CLIENT_URL_PROD : process.env.CLIENT_URL_DEV;
app.use((0, cors_1.default)({
    origin,
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
}));
// const httpsOptions = {
//   key: fs.readFileSync(path.join(__dirname, "./bin/key.pem")),
//   cert: fs.readFileSync(path.join(__dirname, "./bin/cert.pem")),
// };
// Dùng logger để log HTTP request vào winston
app.use(loggerMiddleware_1.default);
// DB Connectors
(0, db_1.connectDB)();
//ROUTE
app.use("/", index_routes_1.default);
// Middlewares
app.use(notFoundEndpointsHandlers_1.notFoundEndpointsHandler);
app.use(errorHandlers_1.default);
// PORT and Starting Server
const PORT = process.env.PORT || 8080;
const server = http_1.default.createServer(app);
// WEBSOCKET
(0, sockets_1.initSocketServer)(server);
server.listen(PORT);
// https.createServer(httpsOptions, app).listen(PORT, () => {
//   console.log(`⚡️[server]: Server is running at https://localhost:${PORT}`);
// });
