// routes/eventRoutes.js
import express from "express";
import fs from "fs";
import path from "path";
import { Event } from "../models/Event.js";

const router = express.Router();

// ✅ 1. Load events from new_events.json and save to DB
router.post("/load", async (req, res) => {
  try {
    const filePath = path.join(path.resolve(), "langchain", "new_events.json");
    const rawData = fs.readFileSync(filePath, "utf-8");
    const events = JSON.parse(rawData);

    let savedCount = 0;
    for (const ev of events) {
      const exists = await Event.findOne({ where: { title: ev.title, city: ev.location } });
      if (!exists) {
        await Event.create({
          title: ev.title,
          description: ev.description,
          category: ev.category,
          subcategory: ev.subcategory || null,
          city: ev.location,
          startDate: ev.date,
          endDate: ev.date,
          registrationLink: ev.url,
          status: "upcoming"
        });
        savedCount++;
      }
    }
    res.status(200).json({ message: `${savedCount} new events saved.` });
  } catch (err) {
    console.error("❌ Error loading events:", err);
    res.status(500).json({ error: "Failed to load events" });
  }
});

// ✅ 2. Fetch events filtered by query: ?city=Ahmedabad&interests=Tech,Art
router.get("/", async (req, res) => {
  try {
    const { city, interests } = req.query;
    const categories = interests ? interests.split(",") : null;

    const where = {};
    if (city) where.city = city;
    if (categories) where.category = categories;

    const events = await Event.findAll({ where });
    res.json(events);
  } catch (err) {
    console.error("❌ Error fetching events:", err);
    res.status(500).json({ error: "Failed to fetch events" });
  }
});

export default router;
