import express from "express";
import Event from "../models/Event.js";

const router = express.Router();

// ✅ Get all events (with category & registrationLink)
router.get("/", async (req, res) => {
  try {
    const events = await Event.findAll();
    res.json(events);
  } catch (err) {
    console.error("❌ Error fetching events:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ✅ Get single event by ID
router.get("/:id", async (req, res) => {
  try {
    const event = await Event.findByPk(req.params.id);
    if (!event) {
      return res.status(404).json({ success: false, message: "Event not found" });
    }
    res.json(event);
  } catch (err) {
    console.error("❌ Error fetching event:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

export default router;
