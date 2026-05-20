# AuraGains

A Flutter-based fitness and wellness application built entirely with **Dart and Flutter**, featuring an intelligent post feed algorithm powered by personalized preference scoring.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [User Roles](#user-roles)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)

## Overview

AuraGains is a community-driven platform designed to help users discover, share, and engage with fitness and wellness content. The application uses an intelligent algorithm to personalize the user experience through dynamic preference scoring and smart feed curation.

## Features

- **Personalized Feed**: Content tailored to individual fitness goals and interests.
- **Community Engagement**: View, like, and comment on fitness content within the platform.
- **Content Saving**: Bookmark posts for later reference.
- **Gamified Challenges & Leaderboards**: Participate in community fitness challenges and compete for top ranks on the live leaderboard.
- **Expert Verification**: Distinct visual identifiers that indicate verified expert status across the platform.
- **Public Profiles & Objectives**: Showcase your personal fitness objectives, metrics, and progress statistics on your profile page for the community to view.
- **Training Protocols**: Build and publish your own customized workout regimes, or seamlessly copy and adopt training protocols created by other users to integrate them directly into your own routine.
- **Ask Expert**: Directly consult qualified trainers or create a public "Ask an Expert" post where verified professionals can reply with dedicated guidance pages.
- **Expert Credential Application**: Submit applications directly within the platform to get verified as an industry expert or qualified trainer.
- **Training Dashboard & Analytics**: Effortlessly view and track your active training protocols with a personalized metric dashboard that monitors total workouts completed and cumulative lifting volume.

## User Roles

### Regular User
- Browse and interact with the personalized fitness feed
- Create and publish posts (normal posts, "Ask Expert" posts, or training protocols)
- Engage with community content through likes, comments, and replies
- Save/bookmark favorite posts for later reference
- View and follow other users' public profiles and fitness objectives
- Submit applications to become a verified expert or trainer
- Report inappropriate content or users
- View metrics and analytics from their active training protocols

### Expert / Verified Trainer
- All Regular User capabilities, plus:
- Verified "Expert" badge displayed on profile and content
- Receive and respond to "Ask Expert" posts with dedicated guidance
- Enhanced visibility in the community feed
- Ability to provide professional guidance and mentorship within the platform

### Admin
- Moderate and manage all community content
- Review and approve/dismiss expert verification applications
- Ban or unban users from the platform
- Change user roles (promote to Expert or Admin)
- View platform-wide analytics and statistics
- Monitor and manage user-generated reports
- Delete or manage posts and comments as needed
- Maintain overall platform integrity and community guidelines

## Architecture

AuraGains follows the **Model-View-ViewModel (MVVM)** pattern for clean, maintainable, and testable code.

## Tech Stack
- **Frontend Framework**: Flutter / Dart
- **Backend Cloud Service**: Supabase (PostgreSQL Database)
- **Authentication**: Supabase Auth
