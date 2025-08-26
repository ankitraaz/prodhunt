import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/** 🔧 Helper: Build trending for a given UTC date (00:00–24:00) */
async function buildTrendingForDate(target: Date) {
    const start = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth(), target.getUTCDate()));
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + 1);

    // Fetch published products launched today, sorted by upvotes
    const snap = await db
        .collection("products")
        .where("status", "==", "published")
        .where("launchDate", ">=", start)
        .where("launchDate", "<", end)
        .orderBy("launchDate")
        .orderBy("upvoteCount", "desc")
        .limit(50)
        .get();

    const topProducts = snap.docs.map((doc, i) => {
        const d = doc.data();
        return {
            productId: doc.id,
            rank: i + 1,
            upvoteCount: d.upvoteCount ?? 0,
            productName: d.name ?? "",
            productTagline: d.tagline ?? "",
            productLogo: d.logo ?? "",
            creatorUsername: d.creatorInfo?.username ?? "Unknown",
            productLaunchDate: d.launchDate ?? null,
        };
    });

    const dateId = `${start.getUTCFullYear()}-${String(start.getUTCMonth() + 1).padStart(2, "0")}-${String(start.getUTCDate()).padStart(2, "0")}`;

    await db.collection("dailyRankings").doc(dateId).set({
        date: admin.firestore.Timestamp.fromDate(start),
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        period: "daily",
        topProducts,
        totalProducts: topProducts.length,
    }, { merge: true });

    return { dateId, count: topProducts.length };
}

/** 🕛 1) Scheduled function: हर दिन 00:05 UTC पर trending generate */
export const scheduledDailyTrending = functions.pubsub
    .schedule("every day 00:05")
    .timeZone("UTC")
    .onRun(async () => {
        const todayUTC = new Date();
        const res = await buildTrendingForDate(todayUTC);
        console.log("✅ dailyRankings generated:", res);
    });

/** ⚡ 2) Callable function: Manual trigger (सिर्फ admin यूज़ कर सके) */
export const generateDailyTrendingNow = functions.https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
        throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    // Check user role
    const userDoc = await db.collection("users").doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data()?.role !== "admin") {
        throw new functions.https.HttpsError("permission-denied", "Admin only.");
    }

    // Optional: custom date from client (YYYY-MM-DD)
    let target = new Date(); // UTC today
    if (typeof data?.date === "string") {
        const [y, m, d] = data.date.split("-").map((x: string) => parseInt(x, 10));
        if (y && m && d) target = new Date(Date.UTC(y, m - 1, d));
    }

    const res = await buildTrendingForDate(target);
    return res;
});
