

# SkillMe

SkillMe is a Flutter-based skill swapping platform that allows users to exchange skills and services with each other. The app leverages Firebase for authentication, real-time chat, user data storage, and media storage.

## What is SkillMe?

SkillMe is a community-driven platform where users can:
- Offer their skills (e.g., programming, music, design, languages, etc.)
- Find and connect with others who have skills they want to learn
- Swap skills through direct chat and requests
- Rate and review each other after a skill swap

## Key Features

- **User Authentication:** Secure sign-up and login using Firebase Auth.
- **Profile Management:** Users can set up profiles, list skills offered/wanted, and manage their availability.
- **Skill Discovery:** Browse and search users by skill categories.
- **Skill Swapping:** Swipe-based interface to find potential matches for skill exchange.
- **Requests & Chat:** Send/receive requests, chat in real-time, and coordinate swaps.
- **Ratings & Reviews:** After a swap, users can rate and review each other.
- **Notifications:** Get notified about new requests, messages, and swap completions.

## Main Screens

- **Home:** Browse users by categories and search for specific skills.
- **Swap:** Swipe through user cards to find a match for skill exchange.
- **Requests:** Manage incoming/outgoing swap requests and chat with users.
- **Profile:** View and edit your profile, see your ratings, and manage your skills.

## Tech Stack

- **Flutter:** Cross-platform mobile app framework.
- **Firebase:** Auth, Firestore (database), Storage, and Cloud Functions.
- **Provider:** State management.
- **Other Packages:** Curved navigation bar, image picker, rating bar, shimmer effects, etc.

## How it Works

1. **Sign Up/Login:** Users create an account and set up their profile.
2. **List Skills:** Add skills you can offer and those you want to learn.
3. **Find Matches:** Use the home or swap screen to find users with complementary skills.
4. **Send Requests:** Initiate a swap request or chat directly.
5. **Chat & Swap:** Discuss details, schedule sessions, and exchange skills.
6. **Rate & Review:** After the swap, leave feedback for your partner.

## Project Structure

- `lib/Screen/User/`: Main user-facing screens (home, swap, requests, chat, profile)
- `lib/models/`: Data models (e.g., user model)
- `lib/providers/`: State management (app state, user data)
- `assets/`: App icons and images
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Platform-specific code

## Getting Started

1. **Clone the repo**
2. **Install dependencies:**  
	`flutter pub get`
3. **Set up Firebase:**  
	Add your Firebase config files (`google-services.json` for Android, etc.)
4. **Run the app:**  
	`flutter run`
