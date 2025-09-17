import express from "express";
import bcrypt from "bcryptjs";
import User from "../models/User.js";

const router = express.Router();

// ✅ REGISTER ROUTE (with bcrypt & role)
router.post("/register", async (req, res) => {
  try {
    console.log("📩 Register API Hit:", req.body);
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, error: "All fields required" });
    }

    // ✅ Check if email already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ success: false, error: "Email already exists" });
    }

    // ✅ Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // ✅ Create user with role (default = user)
    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      city: null,
      interests: [],
      role: role || "user", // <-- ✅ Save role here
    });

    return res.json({
      success: true,
      message: "User Registered",
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
      },
    });
  } catch (err) {
    console.error("❌ Error in Register:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

// ✅ LOGIN ROUTE (with bcrypt & role in response)
router.post("/login", async (req, res) => {
  try {
    const { email, password, loginAs } = req.body; // loginAs = 'user' or 'pro'

    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(400).json({ success: false, message: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ success: false, message: "Invalid credentials" });

    // ✅ Role enforcement
    if (loginAs && loginAs !== user.role) {
      return res.status(403).json({ success: false, message: `Not a ${loginAs} account` });
    }

    return res.json({
      success: true,
      message: "Login successful",
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
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
    console.log("📩 Preferences API Hit:", req.body);
    const { email, city, interests } = req.body;

    if (!email || !city || !interests) {
      return res.status(400).json({ success: false, message: "Email, city & interests required" });
    }

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    user.city = city;
    user.interests = interests;
    await user.save();

    res.json({ success: true, message: "Preferences updated successfully" });
  } catch (err) {
    console.error("❌ Preferences Update Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ✅ GET PREFERENCES
router.get("/preferences", async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({ success: false, message: "Email required" });
    }

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({
      success: true,
      preferences: {
        city: user.city,
        interests: user.interests || [],
      },
    });
  } catch (err) {
    console.error("❌ Get Preferences Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

//router.post("/upgrade", async (req, res) => {
  //const { email, plan } = req.body;
  //const user = await User.findOne({ where: { email } });
  //if (!user) return res.status(404).json({ success: false, message: "User not found" });

  // Mark as pro (optional, can be after payment success in real app)
  //user.role = "pro";
  //await user.save();

  // Generate payment URL
  //const paymentUrl = `https://payment-gateway.com/checkout?session_id=${plan}_${Date.now()}`;

  //res.json({ success: true, paymentUrl });
//});



export default router;
