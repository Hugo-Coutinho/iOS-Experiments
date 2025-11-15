# 🧵 Data Race & Race Conditions in Swift  
Understanding Concurrency Pitfalls and How to Avoid Them

[![Swift](https://img.shields.io/badge/Swift-Concurrency-orange?logo=swift)]()
[![Thread Safety](https://img.shields.io/badge/Thread%20Safety-Actors-blue)]()
[![Blog Post](https://img.shields.io/badge/Full%20Article-Read-blueviolet)](https://bloghugocoutinho.wordpress.com/2025/11/13/data-race-and-race-conditions/)

---

## 📌 Overview
This article explains the difference between **data races** and **race conditions**, why they happen in concurrent code, and how Swift’s structured concurrency (especially **actors**) helps prevent them.

---

## 🔍 What Are They?

### **Data Race**
A data race occurs when two or more threads access the same memory at the same time, and at least one of them writes to it.  
This leads to **undefined behavior**, crashes, or inconsistent data.

### **Race Condition**
A race condition appears when the final result depends on the *timing or ordering* of concurrent operations.  
If tasks finish in an unexpected order, your app may behave incorrectly.

---

## ⚠️ What Can Cause It?

### **1. Shared Object**
When multiple concurrent tasks modify the same instance without isolation, you can easily introduce a data race.  
👉 The fix: isolate shared mutable state inside a Swift **actor**, ensuring serialized, thread-safe access.

---

### **2. Actor Isolation Leak**
Actors protect their internal state—but only if you keep that state private.  
If you expose mutable stored properties publicly, you bypass the actor's guarantees.  
👉 Keep state **private** and expose values through async methods or computed accessors.

---

### **3. Race in Task Ordering**
`await` inside a loop makes operations run **sequentially**, hurting performance.  
Running tasks concurrently is faster—but completion order is unpredictable.  
👉 If your logic depends on strict ordering, this can create a race condition.

---

## 💡 Recommended Solution

Use **`withTaskGroup`** to run work concurrently:

- Tasks execute in parallel → performance boost  
- Actor isolation ensures safe access  
- The group suspends until *all tasks finish* → avoids ordering issues  

This gives you **both**:  
✔ Concurrency  
✔ Safety  
✔ Deterministic final state

---

## 🔗 Full Article  
👉 **Read the full blog post here:**  
https://bloghugocoutinho.wordpress.com/2025/11/13/data-race-and-race-conditions/

