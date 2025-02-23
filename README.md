# Tempo

Tempo is an iOS music social media and listening application built with SwiftUI. Designed for production and optimized for the Apple App Store, Tempo elevates music discovery, social interaction, and personalized listening insights in an elegant and efficient interface.

## Overview

Tempo is a free music-sharing application for iOS. Anyone can log into their music platform (Spotify, Apple Music, SoundCloud, YouTube Music, etc.) to showcase and *use* their music library. The app takes two avenues: social media and AI listening. The social media aspect is just like any other. Users have personalized profiles that display statistics of their listening habits such as genre breakdown and listening history, along with their top songs, artists, and playlists. They can follow friends or find someone new to learn about their listening habits or check their compatibility using the compatibility score. Next is AI listening. Simply describe what you want to listen to: “I want something similar in vibe to Mt. Joy,” “Give me only John Mayer and the Grateful Dead,” or even “I’m driving to Maine to go snowboarding.” NLP takes your prompt and curates a tailored, infinite queue of music that perfectly matches your request, played directly on Tempo. The music will either be from your music library, the people you follow, or a mixture of the two depending on your preferences. 

The app is organized into three main tabs:
- **Listen:** Discover personalized music recommendations by entering prompts (e.g., “chill acoustic vibes”).
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

**Login & Onboarding:** A user logs in with their Spotify account to start the onboarding process.
<img width="1438" alt="Screenshot 2025-02-11 at 12 27 46 PM" src="https://github.com/user-attachments/assets/6781f715-9313-44f5-a105-5ebab7406655" />


**Listen Tab (Music Discovery):** Enter a music prompt for a curated playlist tailored to your unique taste—or even influenced by the people you follow.
<img width="1438" alt="Screenshot 2025-02-11 at 12 28 00 PM" src="https://github.com/user-attachments/assets/7f344869-bf05-4280-81c4-08dbfeb57d73" />


**Community Tab (Compatibility Web):** Visualize musical compatibility scores with friends and discover new ones.
<img width="1438" alt="Screenshot 2025-02-11 at 12 26 12 PM" src="https://github.com/user-attachments/assets/24417f23-955a-4572-a018-d0b86ae139e2" />


**Profile Tab (Listening Insights):** Detailed listening analytics along with top songs, artists, and playlists.
<img width="1438" alt="Screenshot 2025-02-11 at 12 26 16 PM" src="https://github.com/user-attachments/assets/7439a6c1-602c-4da6-8e0a-e2cb63ef8139" />


## Current Status

Tempo is actively being developed.

## License
This project is proprietary. All rights are reserved. No part of this software—including its source code, design, or documentation—may be reproduced or distributed without prior written permission from the copyright holder. For complete details on the licensing terms, please refer to the LICENSE file in the root directory.

## Acknowledgements

- **Spotify API:** For providing the robust music library and authentication services.
- **OpenAI:** For advanced natural language processing that powers the recommendation engine.
- **Firebase:** For real-time data synchronization and persistence.
- **Apple SwiftUI:** For a modern, responsive UI framework that enables rapid development.
