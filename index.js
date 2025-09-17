import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import sequelize from "./config/db.js";
import authRoutes from "./routes/authRoutes.js";
import eventRoutes from "./routes/eventRoutes.js";
import paymentRoutes from "./routes/paymentRoutes.js"
import eventChecker from "./eventChecker.js"; // 🕒 MySQL cleanup + Flask sync

dotenv.config();

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ Middleware
app.use(
  cors({
    origin: "*", // 🔁 Change to specific origin if Flutter frontend is deployed
    credentials: true,
  })
);
// ✅ Routes
app.get("/", (req, res) => {
  res.json({ message: "✅ Node API is running" });
});

// ✅ Test route for connectivity
app.get("/api/auth/test", (req, res) => {
  res.json({ message: "✅ Node Auth API is reachable" });
});

app.use("/api/auth", authRoutes);
app.use("/api/events", eventRoutes);
app.use("/api/payment", paymentRoutes);

app.get("/", (req, res) => res.json({ message: "Node API running" }));

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log("✅ Connected to MySQL Database");

    await sequelize.sync(); // Optional: use { alter: true } during development
    console.log("🛠️ Database synced");

   app.listen(PORT, "0.0.0.0", () => {
     console.log(`🚀 Server running at: http://0.0.0.0:${PORT}`);
   });

    // 🕒 Start background scheduler (clean + reload)
    eventChecker();
  } catch (err) {
    console.error("❌ Failed to connect DB or start server:", err.message);
    process.exit(1);
  }
};

startServer();
