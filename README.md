# 🎬 Movie Reviews Website

A cross-platform **Flutter application** for browsing movies and managing user reviews.  
The project is designed to integrate **The Movie Database (TMDB) API** for movie data and **Firebase** for authentication and data storage.

---

## 📌 Project Overview

The Movie Reviews Website allows users to explore movies, view details, and interact with movie-related content.  
The application is built using Flutter and targets **Android, iOS, and Web** platforms.

The system is structured to:
- Fetch movie data from **TMDB API**
- Manage users and reviews using **Firebase**
- Provide a clean and responsive UI using Flutter widgets

---

## 🛠️ Technologies Used

### Frontend / Client
- **Flutter (Dart)**
- Material UI components

### External APIs
- **TMDB API** – movie listings, details, ratings, posters

### Backend / Services
- **Firebase**
  - Firebase Authentication (user login/signup)
  - Cloud Firestore (store user reviews and ratings)
  - Firebase Hosting (web support – optional)

---

## 📂 Project Structure

```text
Movie_Reviews_Website/
├── android/                # Android platform code
├── ios/                    # iOS platform code
├── web/                    # Flutter web support
├── lib/                    # Flutter application source code
├── test/                   # Unit and widget tests
├── project-firebase/       # Firebase project configuration
├── firebase.json           # Firebase setup file
├── pubspec.yaml            # Dependencies and configuration
├── untitled4.zip           # Backup of original project
└── README.md               # Project documentation
