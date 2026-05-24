# Modul AI — SkillBantuin

Folder ini berisi 6 algoritma AI yang terintegrasi penuh ke dalam aplikasi SkillBantuin. Setiap modul dipilih berdasarkan relevansinya terhadap domain platform freelance.

---

## Ringkasan Modul

| # | File | Algoritma | Digunakan Di |
|---|------|-----------|--------------|
| 1 | `search_engine.dart` | **Algoritma Pencarian — BM25** | `freelancer_search_screen.dart` |
| 2 | `expert_system.dart` | **Sistem Pakar — Forward Chaining** | `client_offers_screen.dart` |
| 3 | `sentiment_analyzer.dart` | **NLP — Analisis Sentimen** | `client_review_screen.dart` |
| 4 | `fuzzy_matcher.dart` | **Logika Fuzzy — FIS Mamdani** | `client_offers_screen.dart` |
| 5 | `genetic_optimizer.dart` | **Algoritma Genetika** | `freelancer_offer_form_screen.dart` |
| 6 | `concept_learner.dart` | **Concept Learning — Find-S** | `client_offers_screen.dart` |
| 7 | `ai_service.dart` | **Facade / Entry Point** | Semua modul di atas |

---

## 1. Algoritma Pencarian — BM25

**File:** `search_engine.dart`  
**Layar:** `FreelancerSearchScreen` (toggle BM25 aktif)

BM25 (Best Match 25) adalah algoritma ranking information retrieval yang merupakan generalisasi dari TF-IDF. Digunakan untuk mengurutkan task berdasarkan relevansi terhadap query pencarian freelancer.

```
Score(D,Q) = Σ IDF(qi) × [tf(qi,D) × (k₁+1)] / [tf(qi,D) + k₁×(1 − b + b×|D|/avgdl)]
k₁ = 1.5   (saturasi frekuensi term)
b  = 0.75  (normalisasi panjang dokumen)
```

---

## 2. Sistem Pakar — Forward Chaining

**File:** `expert_system.dart`  
**Layar:** `ClientOffersScreen` (AI ranking penawaran)

Knowledge base berisi 10 aturan IF-THEN dengan bobot berbeda. Mekanisme forward chaining mengakumulasi bobot semua aturan yang terpicu untuk menghasilkan skor rekomendasi.

**Contoh aturan:**
- R1: IF rating ≥ 4.5 → skor += 0.25 (Premium)
- R10: IF rating ≥ 4.5 AND completedTasks ≥ 15 → skor += 0.30 (Kombinasi sempurna)

---

## 3. NLP — Analisis Sentimen

**File:** `sentiment_analyzer.dart`  
**Layar:** `ClientReviewScreen` (live sentiment saat mengetik ulasan)

VADER-inspired lexicon & rule-based sentiment analysis. Mendukung Bahasa Indonesia dan Inggris. Fitur: deteksi negasi, amplifier (sangat/very), dampener (agak/somewhat).

```
compound = raw / √(raw² + 15)
Positif ≥ 0.05 | Negatif ≤ -0.05 | Netral: antara keduanya
```

---

## 4. Logika Fuzzy — FIS Mamdani

**File:** `fuzzy_matcher.dart`  
**Layar:** `ClientOffersScreen` (skor kesesuaian tiap penawaran)

Fuzzy Inference System 3 variabel input: budget_gap, rating, pengalaman → output: suitability score (0–100). Menggunakan 20 aturan fuzzy IF-THEN.

**Pipeline:**
1. Fuzzifikasi (trapezoid, segitiga, shoulder)
2. Evaluasi aturan (min = AND)
3. Agregasi output (max method)
4. Defuzzifikasi (centroid/CoG)

---

## 5. Algoritma Genetika — Optimasi Penawaran

**File:** `genetic_optimizer.dart`  
**Layar:** `FreelancerOfferFormScreen` (tombol "Jalankan Optimasi AI")

GA menemukan kombinasi budget & deadline terbaik yang memaksimalkan kemungkinan penawaran diterima client.

**Parameter:**
- Populasi: 60 individu
- Generasi: 80
- Crossover: Uniform, 80%
- Mutasi: Gaussian, 15%
- Elitisme: 3 individu terbaik

**Fungsi Fitness:**
```
fitness = budget_score×0.40 + deadline_score×0.30 + credibility_score×0.30
```

---

## 6. Concept Learning — Find-S

**File:** `concept_learner.dart`  
**Layar:** `ClientOffersScreen` (label Relevan/Kurang Relevan)

Algoritma Find-S dari Concept Learning yang mencari hipotesis paling spesifik konsisten dengan semua contoh positif. Atribut: categoryMatch, budgetRange, experienceLevel, ratingTier, locationType.

---

## Penggunaan via AIService

```dart
import 'package:skillbantuin/lib/ai/ai_service.dart';

final ai = AIService.instance;

// BM25 Search
final results = ai.searchTasks(tasks, 'instalasi atap');

// Expert System
final rankings = ai.rankOffers(offers, task);

// NLP Sentiment
final sentiment = ai.analyzeSentiment('Freelancer sangat profesional!');

// Fuzzy Logic
final suitability = ai.evaluateSuitability(taskBudget: 1500000, offeredBudget: 1200000, rating: 4.5, completedTasks: 20);

// Genetic Algorithm
final gaResult = ai.optimizeOffer(clientBudget: 1500000, clientDeadlineDays: 30, freelancerRating: 4.2, completedTasks: 12);

// Concept Learning
final classification = ai.classifySkillRelevance(taskCategory: 'Konstruksi', freelancerSkill: 'Bangunan & Sipil', ...);
```

---

## Demo Interaktif

Buka **AIFeaturesScreen** dari tombol ✨ di AppBar dashboard client atau freelancer untuk demo real-time semua algoritma dengan slider dan input langsung.
