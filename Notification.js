import { DataTypes } from "sequelize";
import sequelize from "../db.js";

const Notification = sequelize.define("Notification", {
  userEmail: { type: DataTypes.STRING, allowNull: false },
  eventId: { type: DataTypes.INTEGER, allowNull: false },
});

export default Notification;
