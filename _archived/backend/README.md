# Archived Dart Shelf Backend (`_archived/backend/`)

> **Archived Date**: July 2026

## Overview

This directory contains the original Dart Shelf HTTP backend API designed for Cloud Run.

## Why it is Archived

1. **Direct Firestore Architecture**: The Flutter mobile application uses `FirestoreService` to execute direct, offline-first transactions backed by `firestore.rules` (Role-Based Access Control).
2. **Duplication Avoidance**: The handlers in this directory (`appointment_handler.dart`, `availability_handler.dart`, `doctor_handler.dart`) duplicate logic that is natively handled by client-side Firestore transactions and security rules.
3. **Future Migration**: If high-volume server-side workloads require Cloud Run in Phase 3+, this code can be reactivated and updated to use the Firebase Admin SDK for local JWT verification.
