import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/* ========== 🔔 Notification on new comment ========== */
export const onNewComment = functions.firestore
    .document("products/{productId}/comments/{commentId}")
    .onCreate(async (snap, context) => {
        const comment = snap.data();
        const { productId } = context.params;

        if (!comment) return;

        const productDoc = await db.collection("products").doc(productId).get();
        if (!productDoc.exists) {
            console.log("❌ Product not found:", productId);
            return;
        }

        const product = productDoc.data();
        const ownerId = product?.createdBy;

        console.log("📥 New Comment →", comment);
        console.log("👤 Product Owner:", ownerId, " | Commenter:", comment.userId);

        if (!ownerId) {
            console.log("⚠️ No ownerId found in product");
            return;
        }

        if (comment.userId === ownerId) {
            console.log("⚠️ Owner commented on own product → Skipping notification");
            return;
        }

        await db.collection("notifications").add({
            userId: ownerId,
            type: "comment",
            productId,
            actorId: comment.userId,
            actorName: comment.userInfo?.displayName ?? "Someone",
            actorPhoto: comment.userInfo?.profilePicture ?? "",
            message: `${comment.userInfo?.displayName ?? "Someone"} commented on your product.`,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log("✅ Notification created for owner:", ownerId);
    });

/* ========== 🔔 Notification on upvote ========== */
export const onNewUpvote = functions.firestore
    .document("products/{productId}/upvotes/{userId}")
    .onCreate(async (snap, context) => {
        const upvote = snap.data();
        const { productId } = context.params;

        if (!upvote) return;

        const productDoc = await db.collection("products").doc(productId).get();
        if (!productDoc.exists) {
            console.log("❌ Product not found:", productId);
            return;
        }

        const product = productDoc.data();
        const ownerId = product?.createdBy;

        console.log("📥 New Upvote →", upvote);
        console.log("👤 Product Owner:", ownerId, " | Upvoter:", upvote.userId);

        if (!ownerId) {
            console.log("⚠️ No ownerId found in product");
            return;
        }

        if (upvote.userId === ownerId) {
            console.log("⚠️ Owner upvoted own product → Skipping notification");
            return;
        }

        await db.collection("notifications").add({
            userId: ownerId,
            type: "upvote",
            productId,
            actorId: upvote.userId,
            actorName: upvote.userInfo?.displayName ?? "Someone",
            actorPhoto: upvote.userInfo?.profilePicture ?? "",
            message: `${upvote.userInfo?.displayName ?? "Someone"} upvoted your product.`,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log("✅ Notification created for owner:", ownerId);
    });

/* ========== 📈 Trending Builder Helpers ========== */
async function buildTrendingForDate(target: Date) {
    const start = new Date(
        Date.UTC(target.getUTCFullYear(), target.getUTCMonth(), target.getUTCDate())
    );
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + 1);

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

    const dateId = `${start.getUTCFullYear()}-${String(
        start.getUTCMonth() + 1
    ).padStart(2, "0")}-${String(start.getUTCDate()).padStart(2, "0")}`;

    await db
        .collection("dailyRankings")
        .doc(dateId)
        .set(
            {
                date: admin.firestore.Timestamp.fromDate(start),
                generatedAt: admin.firestore.FieldValue.serverTimestamp(),
                period: "daily",
                topProducts,
                totalProducts: topProducts.length,
            },
            { merge: true }
        );

    return { dateId, count: topProducts.length };
}

/* 🕛 Scheduled job */
export const scheduledDailyTrending = functions.pubsub
    .schedule("every day 00:05")
    .timeZone("UTC")
    .onRun(async () => {
        const todayUTC = new Date();
        const res = await buildTrendingForDate(todayUTC);
        console.log("✅ dailyRankings generated:", res);
    });

/* ⚡ Callable job */
export const generateDailyTrendingNow = functions.https.onCall(
    async (data, context) => {
        if (!context.auth?.uid) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "Login required."
            );
        }

        const userDoc = await db.collection("users").doc(context.auth.uid).get();
        if (!userDoc.exists || userDoc.data()?.role !== "admin") {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Admin only."
            );
        }

        let target = new Date(); // today UTC
        if (typeof data?.date === "string") {
            const [y, m, d] = data.date.split("-").map((x: string) => parseInt(x, 10));
            if (y && m && d) target = new Date(Date.UTC(y, m - 1, d));
        }

        const res = await buildTrendingForDate(target);
        return res;
    }
);
