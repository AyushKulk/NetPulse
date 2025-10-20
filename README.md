# ⚡ **NetPulse: Intelligent Edge AI for Real-Time Network Diagnostics**
By: Ayush, Joe, Max, Sophia

Submission Link: https://devpost.com/software/the-most-optimal-network

## 💡 **Inspiration**  
Every minute of network downtime costs enterprises **thousands of dollars** — yet most monitoring systems are *reactive*, not *preventive.*  
We wanted to change that by giving users — from everyday households to enterprise IT teams — a **live, intelligent pulse** on their network performance.  
With the help of the **T-Mobile 5G Network**, a **Raspberry Pi**, and an **Arduino hardware kit**, we set out to build **NetPulse**, an embedded AI system that brings **predictive network diagnostics to the edge.**

---

## 🚀 **What It Does**  
**NetPulse** is an **end-to-end, real-time intelligent system** that:  
🔹 Collects environmental, motion, and system metrics from onboard sensors (temperature, humidity, CPU load, ping latency, packet loss, etc.)  
🔹 Processes and classifies this data through an **edge anomaly detection model** running locally on the Raspberry Pi  
🔹 Streams all metrics and AI insights to a **mobile dashboard** via **Firestore** and an **MCP Server**, providing instant visualization and personalized optimization tips  

**📱 Mobile App Features:**  
- **Live graphs** of network health metrics (latency, stability, Wi-Fi signal, etc.)  
- **AI-powered diagnostics & recommendations** (e.g., “Reduce router distance” or “High packet loss detected — potential interference”)  
- **Realtime data sync** between Arduino → Phone → MCP Server → Firestore  

---

## 🛠️ **How We Built It**  
**Hardware:** Arduino + environmental & IMU sensors to capture physical and performance parameters  
**Networking:** T-Mobile 5G backbone for stable and fast data transmission  
**Backend:** Python-based Firestore pipeline for structured logging and real-time analytics  
**AI Layer:** Anomaly detection model trained to identify irregular system behavior and generate contextual diagnostics — integrated with an MCP Server running **Claude Sonnet 4.5**  
**Frontend:** Mobile app interface for live metric visualization and AI feedback  

---

## ⚔️ **Challenges We Ran Into**  
- Building a **robust data pipeline** from Arduino → Mobile → MCP → Firestore with low latency  
- Managing **real-time synchronization** between Arduino and Raspberry Pi sensors  
- Ensuring **consistent calibration and normalization** for ML inference  
- Designing an **ML model that performs well** on small, noisy, and unlabeled datasets  

---

## 🏆 **Accomplishments We’re Proud Of**  
- End-to-end integration across hardware, AI, and cloud — with a **fully functional live demo**  
- Successfully collected and parsed thousands of real-world sensor readings  
- Built a responsive mobile UI that visualizes **real-time network health**  
- Developed a **modular ML inference architecture** for seamless edge-to-cloud deployment  

---

## 🧠 **What We Learned**  
- How system-level metrics like **packet loss, CPU load, and Wi-Fi signal strength** can predict instability before users notice  
- The importance of **cleaning and scaling sensor data** for reliable ML predictions  
- How to **design for resilience** — ensuring fault-tolerant data flow from embedded to cloud  

---
