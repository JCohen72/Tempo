# Tempo

Tempo is an iOS music social media and listening application built with SwiftUI. Designed for production and optimized for the Apple App Store, Tempo elevates music discovery, social interaction, and personalized listening insights in an elegant and efficient interface.

## Overview

Tempo integrates the vast Spotify music library with advanced AI via OpenAI’s GPT to offer tailored music recommendations based on natural language prompts. With seamless social connectivity, the app lets users visualize musical compatibility with friends, track their listening habits, and control playback across devices (including Bluetooth speakers) with minimal latency.

The app is organized into three main tabs:
- **Personal:** Discover personalized music recommendations by entering prompts (e.g., “chill acoustic vibes”).
- **Community:** Visualize your musical compatibility with friends via an interactive Compatibility Web.
- **Profile:** Review your personal detailed listening insights—including top songs, playlists, genres, artists and trends/statistics.

## Features

- **Spotify Integration & OAuth 2.0:**  
  Log in securely using your Spotify account. Tokens are automatically generated and refreshed for uninterrupted access to user data (playlists, saved songs, listening history).

- **AI-Powered Music Discovery:**  
  Leverage OpenAI’s GPT to convert natural language prompts into actionable queries, resulting in a curated queue of personalized tracks.

- **Social Connectivity:**  
  The Compatibility Web calculates and displays compatibility scores based solely on a users music library, providing an intuitive visual interface for social interaction.

- **Listening Insights & Analytics:**  
  Access comprehensive statistics (e.g., top 50 tracks, genre breakdown, weekly trends) in the Profile tab, offering users a deep dive into their musical journey.

- **Seamless Playback:**  
  Integration with Bluetooth speakers and on-device controls ensures playback synchronization with latency under 100 milliseconds.

- **Real-Time Data & Persistence:**  
  Firebase Firestore is used to store and retrieve user data, ensuring data continuity across sessions.

## Images

The following screenshots and diagrams illustrate key aspects of Tempo's UI and architecture.
<img width="1385" alt="Screenshot 2025-02-11 at 12 23 12 PM" src="https://github.com/user-attachments/assets/72c50ca7-4629-4dff-ae7e-f4edd9848842" />
<img width="1094" alt="Screenshot 2025-02-11 at 12 23 28 PM" src="https://github.com/user-attachments/assets/4f4f955c-82eb-46b2-b57d-b15ead9a6392" />
<img width="1438" alt="Screenshot 2025-02-11 at 12 23 44 PM" src="https://github.com/user-attachments/assets/7de8f22e-3cf0-4cf7-9c24-6c185fa70d0f" />
<img width="1438" alt="Screenshot 2025-02-11 at 12 23 51 PM" src="https://github.com/user-attachments/assets/4fce3fcf-b7f6-432b-8e9b-3f5379a9e497" />

- **Login & Onboarding:**  
  ![Login Screen](Images/login-screen.png)  
  A user logs in with their Spotify account to start their journey.

- **Personal Tab (Music Discovery):**  
  ![Personal Tab](Images/personal-tab.png)  
  Enter a music prompt and receive a curated list of tracks.

- **Community Tab (Compatibility Web):**  
  ![Community Tab](Images/community-tab.png)  
  Visualize musical compatibility scores with friends.

- **Profile Tab (Listening Insights):**  
  ![Profile Tab](Images/profile-tab.png)  
  Detailed analytics including top songs, genres, and playlists.
  
## Current Status

Tempo is actively being developed.

## License
© 2025 Joseph E. Cohen. All rights reserved.
No part of this software—including its source code, design, or documentation—may be reproduced, distributed, or transmitted in any form or by any means, without prior written permission from the copyright holder.

## Acknowledgements

- **Spotify API:** For providing the robust music library and authentication services.
- **OpenAI:** For advanced natural language processing that powers the recommendation engine.
- **Firebase:** For real-time data synchronization and persistence.
- **Apple SwiftUI:** For a modern, responsive UI framework that enables rapid development.
