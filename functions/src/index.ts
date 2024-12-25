/**
 * /functions/src/index.ts
 */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import fetch from "node-fetch";

initializeApp();

/**
 * Structure of data expected by generateFirebaseToken function.
 */
interface GenerateTokenRequestData {
  spotifyAccessToken: string;
}

/**
 * Example structured error codes we might want to throw.
 * See:
 * https://firebase.google.com/docs/functions/callable-reference#function_return_types_errors_and_metadata
 */
enum MyErrorCode {
  MISSING_ACCESS_TOKEN = "missing-access-token",
  SPOTIFY_UNAUTHORIZED = "spotify-unauthorized",
  SPOTIFY_GENERIC = "spotify-generic",
  UNKNOWN_ERROR = "unknown-error",
}

/**
 * Cloud Function that generates a Firebase custom token
 * using a Spotify Access Token.
 */
export const generateFirebaseToken = onCall<GenerateTokenRequestData>(
  async (request) => {
    try {
      /*
       * NO LONGER NEED FOR CURRENT FLOW BUT SAVING FOR FUTURE USE
       * STEP 0: Pull the Spotify secret from environment variables.
       * const spotifyClientSecret = process.env.SPOTIFY_CLIENT_SECRET || "";
       * if (!spotifyClientSecret) {
       *   throw new Error("SPOTIFY_CLIENT_SECRET not set in env variables.");
       * }
       */

      logger.info(
        "generateFirebaseToken called",
        {hasAuthContext: !!request.auth},
      );

      // STEP 1: Validate the input
      const {spotifyAccessToken} = request.data;
      if (!spotifyAccessToken) {
        throw new HttpsError(
          "invalid-argument",
          "Missing required field: 'spotifyAccessToken'.",
          {code: MyErrorCode.MISSING_ACCESS_TOKEN},
        );
      }

      // STEP 2: Validate the Spotify Access Token
      const resp = await fetch(
        "https://api.spotify.com/v1/me",
        {
          headers: {
            Authorization: `Bearer ${spotifyAccessToken}`,
          },
        },
      );

      if (!resp.ok) {
        const body = await resp.text();
        logger.error(
          "Spotify /v1/me call failed",
          {status: resp.status, body},
        );

        if (resp.status === 401) {
          // Typically 401 => invalid/expired token
          throw new HttpsError(
            "unauthenticated",
            "Spotify token is invalid or expired.",
            {code: MyErrorCode.SPOTIFY_UNAUTHORIZED},
          );
        } else {
          throw new HttpsError(
            "failed-precondition",
            `Spotify token validation failed: ${resp.status}`,
            {code: MyErrorCode.SPOTIFY_GENERIC, body},
          );
        }
      }

      const spotifyProfile = (await resp.json()) as {
        id: string;
        display_name?: string;
        email?: string;
      };

      if (!spotifyProfile.id) {
        throw new HttpsError(
          "failed-precondition",
          "Spotify profile missing 'id' field.",
          {code: MyErrorCode.SPOTIFY_GENERIC},
        );
      }

      // STEP 3: Create a Firebase custom token using the Spotify user ID
      const userId = spotifyProfile.id;
      const displayName = spotifyProfile.display_name || "";
      const email = spotifyProfile.email || "";

      logger.info(
        "Spotify user validated",
        {userId, displayName, email},
      );

      const auth = getAuth();
      const customToken = await auth.createCustomToken(
        userId,
        {displayName, email},
      );

      logger.info(
        "Created Firebase custom token for Spotify user",
        {userId},
      );

      // STEP 4: Return success
      return {token: customToken};
    } catch (error: unknown) {
      logger.error("Error in generateFirebaseToken", {error});

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "unknown",
        (error as Error).message || "Unknown error occurred",
        {code: MyErrorCode.UNKNOWN_ERROR},
      );
    }
  },
);
