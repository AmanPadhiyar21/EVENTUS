import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Event = sequelize.define(
  "Event",
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    title: { type: DataTypes.STRING(255), allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    category: { type: DataTypes.STRING(100), allowNull: true },
    city: { type: DataTypes.STRING(100), allowNull: true },
    startDate: { type: DataTypes.DATEONLY, allowNull: true },
    endDate: { type: DataTypes.DATEONLY, allowNull: true },
    registrationLink: { type: DataTypes.STRING(500), allowNull: true },
    status: { type: DataTypes.STRING(20), allowNull: true },
  },
  {
    tableName: "events",
    timestamps: false,
  }
);

export default Event;
