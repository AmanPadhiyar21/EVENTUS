import express from "express";
import User from "../models/User.js";

const router = express.Router();

// Mock upgrade route
router.post("/mock-upgrade", async (req, res) => {
  try {
    const { userId, plan } = req.body;

    if (!userId || !plan) {
      return res
        .status(400)
        .json({ success: false, message: "userId and plan are required" });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "User not found in DB" });
    }

    // Upgrade user
    user.role = "pro";
    user.plan = plan;
    await user.save();

    return res.json({ success: true, message: "Upgraded to Pro", user });
  } catch (err) {
    console.error("Mock upgrade error:", err);
    return res
      .status(500)
      .json({ success: false, message: "Server error during upgrade" });
  }
});

export default router;
