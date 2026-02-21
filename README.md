![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/Platform-iOS-blue)
![License](https://img.shields.io/badge/License-MIT-green)

# Wluey – Adaptive Menstrual Cycle Analytics Engine (iOS)

Wluey is a SwiftUI-based menstrual cycle tracking application featuring a robust, adaptive, calendar-based prediction engine designed with statistical smoothing, variance modeling, and heuristic clinical logic.

This project explores how far a deterministic, non-hormonal model can go in predicting menstrual cycles using time-series analysis and robust statistical techniques.

> ⚠️ This application is NOT a medical device and does not replace professional medical advice.

---

## 🎯 Project Objective

The goal of Wluey is to:

- Build a structured menstrual cycle analytics engine from first principles
- Apply statistical robustness techniques (IQR filtering, smoothing, weighted averaging)
- Model prediction confidence based on variance and sample size
- Evaluate realistic accuracy ceilings of calendar-based prediction models
- Explore research-informed heuristics for fertility estimation

---

## 🏗 Architecture Overview

The application follows a layered architecture:

```
DailyLog (Data Layer)
        ↓
PeriodExtractor
        ↓
CycleEngine (Statistical Core)
        ↓
PredictionEngine
        ↓
ConfidenceEngine
        ↓
HealthWarningEngine
        ↓
UI Layer (SwiftUI)
```

### Layers

- **Data Layer**: Raw cycle logs
- **Domain Layer**: Statistical and predictive engines
- **ViewModel Layer**: State management
- **UI Layer**: SwiftUI interface

---

## 🧠 Cycle Engine – Core Logic

The prediction model is built on:

### 1️⃣ Robust Cycle Estimation
- Interquartile Range (IQR) outlier removal
- Exponential smoothing (Brown, 1956)
- Weighted robust averaging
- Adaptive luteal phase estimation

### 2️⃣ Ovulation Estimation
Ovulation ≈ Average Cycle Length − Luteal Phase

Fertile window modeled as:
```
Ovulation − 5 days → Ovulation
```

Based on research by:
- Wilcox AJ et al., NEJM (1995)

### 3️⃣ Confidence Modeling
Confidence score derived from:
- Sample size (cycle count)
- Standard deviation (cycle variability)

Confidence ∝ (Data Volume × Stability)

### 4️⃣ Health Heuristics
The system detects:
- Long period duration
- High cycle variability
- Short luteal phase
- Extended amenorrhea (>60 days)
- Pattern variability suggestive of further monitoring

These are rule-based indicators and NOT diagnostic tools.

---

## 📊 Statistical Model

Given cycle lengths:

```
[36, 34, 39, 29]
```

Mean ≈ 34.5 days  
Standard Deviation ≈ 3.64 days  

Theoretical Mean Absolute Error (MAE):

```
MAE ≈ σ × √(2/π)
MAE ≈ 3.64 × 0.798 ≈ 2.9 days
```

This places the realistic calendar-based prediction ceiling at:

- ±2 days → ~40–50%
- ±3 days → ~60%
- ±4 days → ~70–75%
- ±5 days → ~80–85%

Without hormonal input (LH / BBT), the theoretical upper bound remains ~80%.

---

## 📚 Research Foundation

The model is inspired by:

- Ogino–Knaus calendar method
- Wilcox AJ et al. (1995), *Timing of sexual intercourse in relation to ovulation*, NEJM
- Brown (1956), Exponential Smoothing for Time-Series Forecasting
- Tukey (1977), Exploratory Data Analysis (IQR method)
- Bull JR et al. (2019), Real-world menstrual cycle variability studies

This implementation adapts those principles into a deterministic mobile analytics engine.

---

## ⚖️ Accuracy Discussion

Wluey is a calendar-based predictive system.

Realistic performance:

| Cycle Stability | Expected Accuracy |
|-----------------|------------------|
| Regular (σ < 2) | 80–85% (±2–3 days) |
| Moderate (σ 3–5) | 60–75% |
| Irregular (σ > 6) | 40–60% |

Prediction accuracy is biologically limited without hormonal tracking.

---

## 🚀 Technologies

- Swift
- SwiftUI
- Deterministic statistical modeling
- Time-series smoothing
- Modular domain architecture

---

## 🔬 Future Research Directions

Potential improvements include:

- Bayesian ovulation posterior updating
- Probabilistic fertility curve modeling
- Hormonal data integration (LH / BBT)
- Machine learning adaptive variance reduction
- Real-time posterior confidence recalibration

---

## 📌 Disclaimer

This application is for educational and research purposes only.
It is not intended for contraception, diagnosis, or medical treatment.

---

## 👤 Author

Satriya Dwi Mahardhika  
iOS Developer & Informatics Student  

---

## 📄 License

MIT License
