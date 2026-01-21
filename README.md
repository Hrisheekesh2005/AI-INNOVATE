![MATLAB](https://img.shields.io/badge/MATLAB-R2023b-orange?style=for-the-badge&logo=mathworks)
![Machine Learning](https://img.shields.io/badge/Machine%20Learning-Random%20Forest-blue?style=for-the-badge)
![Gen-AI](https://img.shields.io/badge/Generative%20AI-Explainable%20AI-purple?style=for-the-badge)
![Physics-Based](https://img.shields.io/badge/Physics--Based-Terrain%20Modeling-green?style=for-the-badge)
![Award](https://img.shields.io/badge/Award-3rd%20Place%20Winner-gold?style=for-the-badge)

# 🌍 Gen-AI Enabled Micro-Zone Flood & Landslide Risk Prediction System

🏆 **Secured 3rd Place**  
**National Level AI Project Design Competition**  
Conducted by **IHRD & Higher Education Department of Kerala**

---

## 📌 Project Overview

This project presents a **micro-zone level disaster risk prediction system** that integrates **Machine Learning**, **Physics-based terrain analysis**, and **Explainable Generative AI** to predict **flood and landslide risks** for a given location.

Unlike conventional **district or basin-level disaster warning systems**, this solution operates at a **location-specific (micro-zone) level**, making predictions more **accurate, interpretable, and actionable** for real-world disaster preparedness.

---

## 🎯 Objectives

- Predict **Flood**, **Landslide**, or **No Disaster** risk
- Perform **micro-zone level prediction**
- Use **real terrain elevation and slope** from satellite data
- Apply **Machine Learning (Random Forest)** for probabilistic prediction
- Integrate **physics-aware logic** for realistic decision making
- Generate **human-readable explanations and advisories (Gen-AI style)**
- Provide **alert levels** (Green / Orange / Red)
- Compute a **Risk Index (0–100)** and **early warning trends**

---

## 🧠 System Architecture

User Natural Language Query
        ↓
Location Extraction (NLP logic)
        ↓
Geocoding API (Latitude & Longitude)
        ↓
Elevation API (Nearby Points)
        ↓
Physics-Based Slope Calculation
        ↓
Machine Learning Prediction (Random Forest)
        ↓
Physics-Aware Logic Refinement
        ↓
Risk Index & Alert Level
        ↓
Gen-AI Risk Explanation & Advisory


---

## 🔧 Technologies Used

### 🧑‍💻 Platform & Language
- **MATLAB**

### 🤖 Machine Learning
- **Random Forest (TreeBagger)**

### 🌐 APIs
- **OpenStreetMap (Geocoding)**
- **OpenTopodata (SRTM Elevation)**

### 🧠 AI Techniques
- Machine Learning
- Physics-guided modeling
- Explainable, rule-guided Generative AI

### 📊 Visualization
- MATLAB plots
- Probability bar charts
- Color-based alert dashboards

---

## 📥 Input Parameters

- **Rainfall** (mm)
- **Terrain slope** (degrees)
- **Elevation** (meters)
- **Soil type**
  - Clay
  - Laterite
  - Sandy
- **Natural language location query**

---

## 📤 Output Features

- **Disaster probability (%)** for:
  - Flood
  - Landslide
  - No Disaster
- **Risk Index (0–100)**
- **Alert Levels**
  - 🟢 Green – Safe
  - 🟠 Orange – Moderate Risk
  - 🔴 Red – High Risk
- **Gen-AI Risk Explanation**, including:
  - Risk reasoning
  - Alert message
  - Advisory actions
  - Forecast interpretation
- **3-day early warning risk trend**

---

## 🤖 Machine Learning Details

- **Algorithm:** Random Forest  
- **Number of Trees:** 150  
- **Training Data:** 2000 synthetic, physics-guided scenarios  

### Why Random Forest?
- Handles **non-linear relationships**
- Robust to **noise and uncertainty**
- Produces **probabilistic outputs**
- Works well with **mixed numerical and categorical features**

---

## 🧠 Generative AI Component (Explainable Gen-AI)

This project implements an **Explainable, Rule-Guided Generative AI module** that converts:
- Machine learning probabilities
- Terrain slope and elevation
- Rainfall conditions

into **human-readable explanations and safety advisories**.

This approach:
- Mimics **Gen-AI style natural language generation**
- Ensures **explainability and safety**
- Works **offline without external LLM APIs**
- Is suitable for **critical disaster warning systems**

---

## 🏆 Achievement

🥉 **3rd Place – National Level AI Project Design Competition**

### Project recognized for:
- Strong technical depth
- Hybrid AI approach (**ML + Physics + Gen-AI**)
- Real-world disaster relevance
- Clear explanation and effective presentation

---

## 🚀 Future Enhancements

- Live rainfall data integration
- Mobile / web-based dashboard
- Satellite image fusion
- Voice-based alerts
- Multi-language Gen-AI explanations
- IoT sensor integration for real-time monitoring

---

## 👥 Team Members

1. **Jaisy Sunil**  
2. **Hrisheekesh Narayan P E**  
3. **Aardra S V**  
4. **Mohammed Ameen**

---

## 📜 License

This project is intended for **academic and educational purposes only**.

---

✨ *This project demonstrates how Machine Learning, Physics-based modeling, and Explainable Generative AI can be combined to build accurate, interpretable, and reliable micro-zone disaster early warning systems.*
