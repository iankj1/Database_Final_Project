# Database_Final_Project

# 🎮 Children's Game Center Database Management System

This repository contains the **database schema** for a Children's Game Center Billing and Management System, built as part of the Database Management System assignment.  
The project demonstrates how to design and implement a relational database using **MySQL**, with proper constraints and relationships.

---

## 📌 Use Case

The system manages a children's game center where clients (parents/guardians) can:
- Register an account  
- Book games and sessions for their children  
- Make payments and receive receipts  
- Contact support for assistance  

Staff and admins can:  
- Manage games and their schedules  
- Track bookings and payments  
- Monitor attendance for game sessions  
- Handle customer support  

---

## 🛠️ Database Design

### Key Entities
- **Users** → Clients, staff, and admins  
- **Games** → Catalog of available games  
- **Game Sessions** → Scheduled time slots for each game  
- **Bookings** → Reservations made by clients  
- **Payments & Receipts** → Record of all transactions  
- **Carts** → Temporary storage of games before checkout  
- **Support Messages** → Customer service communication  
- **Audit Logs** → Record of critical system events  

### Relationships
- **One-to-One**: `payments ↔ receipts`  
- **One-to-Many**: `users → bookings`, `games → sessions`  
- **Many-to-Many**:  
  - `bookings ↔ games` (through `booking_items`)  
  - `sessions ↔ users` (through `session_attendance`)  

---

## 📂 Files in Repository
- `game_center_schema.sql` → MySQL script with all `CREATE DATABASE`, `CREATE TABLE`, constraints, and relationships.  
- `README.md` → Project documentation (this file).  

---

## ⚡ Installation & Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/game-center-dbms.git
   cd game-center-dbms
