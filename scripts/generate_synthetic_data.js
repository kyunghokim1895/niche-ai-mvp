
const fs = require('fs');
const path = require('path');
require('../functions/node_modules/dotenv').config({ path: path.join(__dirname, '../functions/.env') });

const admin = require("../functions/node_modules/firebase-admin");
try {
    const serviceAccount = require("./service-account.json");
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Admin Initialized (with Service Account).");
} catch (e) {
    if (e.code !== 'app/duplicate-app') console.error("Firebase Auth Error:", e);
}

const db = admin.firestore();

// --- Configuration ---
const API_KEY = process.env.GEMINI_API_KEY;
if (!API_KEY) {
    console.error("ERROR: GEMINI_API_KEY is missing in functions/.env");
    process.exit(1);
}

// Using Gemini Flash Latest via REST API
const MODEL_NAME = "gemini-flash-latest";
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${API_KEY}`;

const USER_PERSONAS = [
    { type: 'INTJ', traits: 'Logical, strategic, perfectionist, hates inefficiency. Struggles with starting if plan isn\'t perfect.' },
    { type: 'ENFP', traits: 'Enthusiastic, creative, easily distracted. Starts many things, finishes few. Needs emotional validation.' },
    { type: 'ISTJ', traits: 'Responsible, detail-oriented, rule-follower. Gets stressed by chaos or unclear instructions.' },
    { type: 'INFP', traits: 'Idealistic, empathetic, sensitive. Needs to feel the "meaning" of the goal. Easily discouraged by harsh feedback.' },
    { type: 'ESTP', traits: 'Action-oriented, pragmatic, bored by theory. Wants immediate results. Ignores long-term planning.' }
];

const ADMIN_PERSONAS = [
    { type: 'Strict PT', traits: 'No excuses, results-oriented, direct, tough love. Use short sentences. Push for action.' },
    { type: 'Warm Therapist', traits: 'Empathetic, validating, gentle, focuses on feelings and mental state. Asks "How does that make you feel?".' },
    { type: 'Strategic Coach', traits: 'Analytical, data-driven, focuses on KPIs and bottlenecks. Asks "What is the root cause?".' },
    { type: 'Motivational Speaker', traits: 'High energy, inspiring, uses metaphors and uplifting language. "You can do this!"' },
    { type: 'Reality Check Manager', traits: 'Balanced, pragmatic, points out feasibility issues politely but firmly. "Is that realistic?"' }
];

const GOALS = [
    "Write a novel",
    "Lose 10kg",
    "Launch a startup",
    "Learn to code",
    "Wake up at 5AM"
];

// --- Helper: Rate Limit Handling ---
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function callGemini(prompt) {
    const payload = {
        contents: [{
            parts: [{ text: prompt }]
        }]
    };

    let attempt = 0;
    while (true) {
        try {
            attempt++;
            if (attempt > 3) throw new Error("Too many retries (3)"); // Limit retries to prevent infinite loops

            console.log(`[API Call] Attempt ${attempt}...`);
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 30000); // 30s timeout

            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
                signal: controller.signal
            });
            clearTimeout(timeoutId);

            console.log(`[API Response] ${response.status} ${response.statusText}`);

            if (response.status === 429) {
                const waitTime = Math.min(Math.pow(1.5, attempt) * 500, 5000);
                console.log(`[Rate Limit] Retrying in ${Math.floor(waitTime)}ms...`);
                await sleep(waitTime);
                continue;
            }

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`API Error ${response.status}: ${errText}`);
            }

            const data = await response.json();
            if (data.candidates && data.candidates.length > 0 && data.candidates[0].content) {
                return data.candidates[0].content.parts[0].text.trim();
            } else {
                console.log("[Warn] Empty response. Retrying...");
                await sleep(1000);
                continue;
            }

        } catch (error) {
            console.log(`[Error] ${error.message}. Retrying...`);
            await sleep(2000);
        }
    }
}


// --- Synthetic Generation Logic ---

async function generateConversation(userP, adminP, goal) {
    const history = [];
    const turns = 3;

    console.log(`\n--- Simulating: User[${userP.type}] vs Coach[${adminP.type}] (Goal: ${goal}) ---`);

    try {
        // 1. Initial User Complaint/Statement
        const userPrompt1 = `
        Role: You are a ${userP.type} persona (${userP.traits}).
        Goal: ${goal}.
        Context: You are struggling with your goal today.
        Task: Write a short message (1-2 sentences) to your coach complaining or explaining why you're stuck.
        Language: Korean (Natural tone).
        `;
        const msg1 = await callGemini(userPrompt1);
        history.push({ sender: 'user', text: msg1, persona: userP.type });
        console.log(`[USER ${userP.type}]: ${msg1}`);
        await sleep(100);

        // Loop for interaction
        for (let i = 0; i < turns; i++) {
            // Coach Reply
            const coachPrompt = `
            Role: You are a ${adminP.type} persona (${adminP.traits}).
            User Input: "${history[history.length - 1].text}"
            User Persona: ${userP.type}.
            Task: Reply to the user. Maintain your persona's tone strictly. Keep it under 200 characters.
            Language: Korean.
            `;
            const coachMsg = await callGemini(coachPrompt);
            history.push({ sender: 'ai', text: coachMsg, persona: adminP.type });
            console.log(`[COACH ${adminP.type}]: ${coachMsg}`);
            await sleep(100);

            // User Reply (if not last turn)
            if (i < turns - 1) {
                const userReplyPrompt = `
                Role: You are a ${userP.type} persona.
                Coach Input: "${coachMsg}"
                Task: Respond to the coach. React according to your personality (e.g. if INTJ and coach is too emotional, be annoyed. If ENFP and coach is strict, be rebellious or discouraged).
                Language: Korean.
                `;
                const userMsg = await callGemini(userReplyPrompt);
                history.push({ sender: 'user', text: userMsg, persona: userP.type });
                console.log(`[USER ${userP.type}]: ${userMsg}`);
                await sleep(100);
            }
        }

        // Save to Firestore
        await db.collection('synthetic_conversations').add({
            user_persona: userP.type,
            admin_persona: adminP.type,
            goal: goal,
            conversation: history,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
        process.stdout.write("Saved ✅\n");
    } catch (e) {
        console.error("Error in conversation generation:", e.message);
    }
}

async function main() {
    console.log("Starting Synthetic Data Generation (Target: 1,000 records)...");
    console.log("NOTE: '429 Rate Limit' messages are normal for the Free Tier. The script will automatically retry.");

    // Generate batch of 1000
    const TOTAL_SAMPLES = 1000;

    for (let i = 0; i < TOTAL_SAMPLES; i++) {
        const u = USER_PERSONAS[Math.floor(Math.random() * USER_PERSONAS.length)];
        const a = ADMIN_PERSONAS[Math.floor(Math.random() * ADMIN_PERSONAS.length)];
        const g = GOALS[Math.floor(Math.random() * GOALS.length)];

        console.log(`\n[${i + 1}/${TOTAL_SAMPLES}] Generating...`);
        await generateConversation(u, a, g);

        // High speed mode: minimal delay
        await sleep(100);
    }

    console.log("\nDone!");
}

main();
