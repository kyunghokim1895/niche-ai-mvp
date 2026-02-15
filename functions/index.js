const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Initialize Gemini
// Note: In production, store API KEY in Firebase Secrets: firebase functions:secrets:set GEMINI_API_KEY
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "YOUR_API_KEY_HERE");
const model = genAI.getGenerativeModel({ model: "gemini-pro" });

exports.sendDailyTriggers = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
  const now = new Date();
  const currentHour = now.getHours();
  // Example: '08:00' matches currentHour 8

  const db = admin.firestore();

  // 1. Query users who have a trigger set for this hour
  // Note: Implementation depends on how you store times. Assuming a simpler 'trigger_hours' array [8, 20]
  const usersSnapshot = await db.collection("users")
    .where("trigger_hours", "array-contains", currentHour)
    .get();

  if (usersSnapshot.empty) {
    console.log("No users to notify this hour.");
    return null;
  }

  const batchPromises = [];

  usersSnapshot.forEach((doc) => {
    const user = doc.data();
    const uid = doc.id;

    // 2. Generate content with Gemini
    const prompt = `
      User Goal: ${user.goal}
      User Motivation (Why): ${user.why}
      Task: Generate a short, punchy, 1-sentence notification to trigger them to act NOW. 
      Tone: If morning, be encouraging. If evening, be reflective.
      Language: Detect the language of the User Goal/Motivation. If Korean, output in Korean. If English, output in English. If mixed, default to Korean (target audience preference).
    `;

    const promise = model.generateContent(prompt)
      .then((result) => {
        const response = result.response.text();

        // 3. Send FCM
        // Assuming 'fcm_token' is stored in user doc
        if (user.fcm_token) {
          const message = {
            notification: {
              title: "Niche AI Companion",
              body: response,
            },
            data: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              screen: "/chat"
            },
            token: user.fcm_token,
          };
          return admin.messaging().send(message);
        }
      })
      .catch((err) => {
        console.error(`Error processing user ${uid}:`, err);
      });

    batchPromises.push(promise);
  });

  await Promise.all(batchPromises);
  console.log(`Processed ${batchPromises.length} triggers.`);
  return null;
});
