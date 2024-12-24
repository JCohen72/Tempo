/**
 * /functions/src/index.ts
 */
import {onCall} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import fetch from "node-fetch";

// 1. Initialize the Firebase Admin SDK once for the environment.
initializeApp();

/**
 * We define the shape of request.data for the callable function.
 */
interface GenerateTokenRequestData {
  spotifyAccessToken: string;
}

/**
 * This Cloud Function uses Google Secret Manager to store secrets,
 * exposed to the runtime as environment variables via
 * 'secretEnvironmentVariables'.
 */
export const generateFirebaseToken = onCall<GenerateTokenRequestData>(
  {
    region: "us-central1", // or preferred region
    memory: "256MiB",
    timeoutSeconds: 60,
    // We'll set secretEnvironmentVariables in firebase.json.
  },
  async (request)=>{
    try {
      // STEP 1: Pull the Spotify secret from environment variables.
      // This variable is auto-injected if we set up
      // secretEnvironmentVariables in firebase.json properly.
      const spotifyClientSecret=process.env.SPOTIFY_CLIENT_SECRET||"";
      if (!spotifyClientSecret) {
        throw new Error("SPOTIFY_CLIENT_SECRET not set in env variables.");
      }

      logger.info("generateFirebaseToken called", {
        hasAuthContext: !!request.auth,
      });

      // STEP 2: Parse input data
      const {spotifyAccessToken}=request.data;
      if (!spotifyAccessToken) {
        throw new Error("Missing required field: 'spotifyAccessToken'");
      }

      // We might not need 'spotifyClientSecret' to validate the token
      // if we only call '/v1/me' on Spotify. But if we do a server-side
      // refresh or advanced calls, we'll use it here.

      // STEP 3: Validate the Spotify Access Token with /v1/me
      const resp=await fetch("https://api.spotify.com/v1/me", {
        headers: {
          Authorization: `Bearer ${spotifyAccessToken}`,
        },
      });

      if (!resp.ok) {
        const body=await resp.text();
        logger.error("Spotify /v1/me call failed", {
          status: resp.status,
          body,
        });
        // Typically 401 => invalid/expired token
        throw new Error(`Spotify token validation failed: ${resp.status}`);
      }

      const spotifyProfile=await resp.json() as {
        id:string;
        display_name?:string;
        email?:string;
      };

      if (!spotifyProfile.id) {
        throw new Error("Spotify profile missing 'id' field.");
      }

      const userId=spotifyProfile.id;
      const displayName=spotifyProfile.display_name||"";
      const email=spotifyProfile.email||"";

      logger.info("Spotify user validated", {
        userId,
        displayName,
        email,
      });

      // STEP 4: Create a Firebase custom token using the Spotify user ID
      const auth=getAuth();
      const customToken=await auth.createCustomToken(userId, {
        displayName,
        email,
      });

      logger.info("Created Firebase custom token for Spotify user", {userId});

      // STEP 5: Return the token to the client
      return {token: customToken};
    } catch (error) {
      logger.error("Error in generateFirebaseToken", {error});
      // Throwing inside onCall returns a structured error to the client
      throw error;
    }
  }
);
