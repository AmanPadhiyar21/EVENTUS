import express from "express";
import bcrypt from "bcryptjs";
import User from "../models/User.js";

const router = express.Router();

// ✅ REGISTER
router.post("/register", async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    if (!name || !email || !password) return res.status(400).json({ success: false, message: "All fields required" });

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) return res.status(400).json({ success: false, message: "Email already exists" });

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      city: null,
      interests: [],
      role: role || "user",
    });

    res.json({ success: true, message: "User registered", user: newUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ✅ LOGIN
router.post("/login", async (req, res) => {
  try {
    const { email, password, loginAs } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(400).json({ success: false, message: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ success: false, message: "Invalid credentials" });

    if (loginAs && loginAs !== user.role) return res.status(403).json({ success: false, message: `Not a ${loginAs} account` });

    res.json({ success: true, message: "Login successful", user: { id: user.id, name: user.name, email: user.email, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ✅ GET PREFERENCES
router.get("/preferences", async (req, res) => {
  try {
    const { email } = req.query;
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    res.json({
      success: true,
      preferences: {
        city: user.city,
        interests: user.interests || [],
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ✅ UPDATE PREFERENCES
router.post("/preferences", async (req, res) => {
  try {
    const { email, city, interests } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    user.city = city;
    user.interests = interests;
    await user.save();

    res.json({ success: true, message: "Preferences updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ✅ UPGRADE TO PRO (return payment URL)

export default router;
