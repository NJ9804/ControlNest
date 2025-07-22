

# 📡 ControlNest – Hierarchical Group Messaging Platform

**ControlNest** is a powerful full-stack platform that enables structured, role-based communication within organizations like colleges or companies. It supports **hierarchical group management**, **Excel-based contact upload**, and **real-time message delivery with notification control**, making internal communication seamless, traceable, and highly targeted.

Built with **Next.js** for the web frontend, **Flutter** for the mobile app, **FastAPI** for the backend, and **PostgreSQL** for the database.

---

## 📌 Table of Contents

* [🚀 Key Features](#-key-features)
* [🏗️ Real-world Use Case](#-real-world-use-case)
* [🛠️ Tech Stack](#-tech-stack)
* [📁 Project Structure](#-project-structure)
* [⚙️ Setup & Installation](#️-setup--installation)
* [📤 Upload Flow](#-upload-flow)
* [🔐 Role and Permissions](#-role-and-permissions)
* [📬 Message Handling](#-message-handling)
* [🧑‍💻 Contributing](#-contributing)


---

## 🚀 Key Features

* 🧱 **Hierarchical Group Creation**
  Create nested groups to reflect your organization’s structure (e.g., `Company > IT > Development > Interns`).

* 📥 **Contact Upload via Excel**
  Bulk upload contacts and assign them to their respective groups using a simple Excel template.

* ✉️ **Targeted Group Messaging**
  Send messages to a specific group or subgroup — only relevant members receive the message.

* 🔄 **Edit/Delete Messages with Sync**
  When a message is edited or deleted, it disappears from both the **sender’s** and **receiver’s** dashboard and notification tray.

* 🔔 **Push Notifications**
  Instant alerts sent to the mobile app for every new message, with clean-up on deletion/edit.

* 📊 **Traceability and Transparency**
  All messages are logged with timestamps, sender, target group, and audit info.

---

## 🏗️ Real-world Use Case

Imagine a **college** structure:

```
College
├── CSE Department
│   ├── HOD
│   ├── Faculty
│   └── Students
│       ├── Final Year
│       └── Juniors
├── ECE Department
└── Admins
```

controlnest/
├── backend/
│   ├── app/
│   │   ├── core/              # Configs, security, init
│   │   │   └── config.py
│   │   │   └── auth.py
│   │   ├── models/            # SQLAlchemy models
│   │   │   └── user.py
│   │   │   └── group.py
│   │   ├── schemas/           # Pydantic schemas
│   │   │   └── user_schema.py
│   │   ├── routers/           # API routes
│   │   │   └── users.py
│   │   │   └── messages.py
│   │   ├── utils/             # Excel, FCM, helper utils
│   │   │   └── excel_parser.py
│   │   │   └── fcm_push.py
│   │   └── main.py            # FastAPI entry point
│   └── requirements.txt
├── frontend/                  # Next.js web app
│   ├── pages/
│   ├── components/
│   ├── services/
│   ├── styles/
│   └── next.config.js
├── mobile/                    # Flutter app
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   └── models/
└── README.md

You can:

* Upload this hierarchy as a group tree.
* Upload contacts via Excel and assign to nodes like "Final Year CSE Students".
* Send messages to `CSE > Students > Final Year` only.
* Edit or delete the message, which updates in real time across all users.

---

## 🛠️ Tech Stack

| Layer         | Tech                           |
| ------------- | ------------------------------ |
| Frontend      | **Next.js (React)**            |
| Mobile App    | **Flutter**                    |
| Backend       | **FastAPI (Python)**           |
| Database      | **PostgreSQL**                 |
| Auth          | JWT + Role-Based Access        |
| File Upload   | Excel parsing with Pandas      |
| Notifications | Firebase Cloud Messaging (FCM) |

---

## 📁 Project Structure

```
controlnest/
├── backend/
│   ├── app/
│   │   ├── models/
│   │   ├── routers/
│   │   ├── core/
│   │   └── utils/          # Excel upload, message utils
│   └── main.py
├── frontend/               # Web app (Next.js)
├── mobile/                 # Flutter mobile app
└── README.md
```

---

## ⚙️ Setup & Installation

### 1. Clone the Repository

```bash
git clone https://github.com/vishnuhari17/controlnest.git
cd controlnest
```

### 2. Backend (FastAPI)

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
fastapi run main.py
```

### 3. Frontend (Next.js)

```bash
cd frontend_final_admin
npm install
npm run dev
```

### 4. Mobile (Flutter)

```bash
cd notification
flutter pub get
flutter run
```

---

## 📤 Upload Flow

### 📁 Group Upload

Upload an Excel file with:

| `group_name` | `parent_name` |
| ------------ | ------------- |
| College      | *(empty)*     |
| CSE          | College       |
| Final Year   | CSE           |

### 👥 Contact Upload

| `name`       | `phone`    | 
| ------------ | ---------- | 
| Ravi         | 9876543210 | 
| Meera        | 9871234567 | 

The system will automatically assign the contact to the corresponding group.

---

## 🔐 Role and Permissions

| Role  | Permissions                                     |
| ----- | ----------------------------------------------- |
| Admin | Manage groups, contacts, send to all            |
| HOD   | Manage dept-level groups, send to dept/subgroup |
| User  | Receive and view messages only                  |

---

## 📬 Message Handling

* **Create:**
  Message is sent to all contacts in the selected group/subgroup. Push notification sent via FCM.

* **Edit/Delete:**
  Message is removed from:

  * Sender’s dashboard
  * Receiver’s dashboard
  * Notification tray (via FCM removal)

* **Audit Trail:**
  All message logs include timestamp, editor, and status (`sent`, `edited`, `deleted`).

---

## 🧑‍💻 Contributing

```bash
# Fork, Clone, and Create a Branch
git checkout -b feature/group-upload-fix

# Commit and Push
git commit -m "Improved group upload error handling"
git push origin feature/group-upload-fix
```

Open a Pull Request 🚀

---


