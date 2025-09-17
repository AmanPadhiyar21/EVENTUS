import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const User = sequelize.define(
  "User",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
    },
    password: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    city: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    interests: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: "user", // ✅ default role
    },
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    plan: {
      type: DataTypes.STRING,
      defaultValue: 'free',
    },
  },
  {
    tableName: "users",
    timestamps: false, // ✅ Prevents Sequelize from expecting updatedAt column
  }
);

export default User;
