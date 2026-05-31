/**
 * weekly-digest Appwrite Function
 *
 * Trigger: CRON schedule, weekly (e.g. `0 13 * * 1` for Mondays at 13:00 UTC).
 *
 * Builds a summary of the top stories from the last 7 days and pushes it to the
 * `weekly-digest` topic. Devices subscribe to that topic client-side.
 *
 * Required env:
 *   APPWRITE_FUNCTION_API_ENDPOINT, APPWRITE_FUNCTION_PROJECT_ID  (auto-injected)
 *   APPWRITE_API_KEY
 *   APPWRITE_DATABASE_ID, APPWRITE_POSTS_COLLECTION_ID
 *   DIGEST_TOPIC_ID            (Appwrite Messaging topic id for the weekly digest)
 *   DIGEST_COUNT               (optional, default 5)
 */
import { Client, TablesDB, Messaging, Query, ID } from 'node-appwrite';

export default async ({ res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const tablesDB = new TablesDB(client);
  const messaging = new Messaging(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const postsCollectionId = process.env.APPWRITE_POSTS_COLLECTION_ID;
  const topicId = process.env.DIGEST_TOPIC_ID;
  const count = Number(process.env.DIGEST_COUNT || '5');

  if (!topicId) {
    error('DIGEST_TOPIC_ID is not set.');
    return res.json({ ok: false, reason: 'no topic configured' });
  }

  try {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const result = await tablesDB.listRows(databaseId, postsCollectionId, [
      Query.greaterThan('$createdAt', since),
      Query.equal('enhanced', true),
      Query.orderDesc('score'),
      Query.limit(count),
      Query.select(['$id', 'title']),
    ]);

    const posts = result.rows ?? [];
    if (posts.length === 0) {
      return res.json({ ok: true, sent: false, reason: 'no posts' });
    }

    const title = `This week on Refetch: ${posts.length} top stories`;
    const body = posts.map((p) => `• ${p.title}`).join('\n');

    await messaging.createPush(
      ID.unique(),
      title,
      body,
      [topicId], // topics
      [],
      [],
      { type: 'digest', postId: posts[0].$id },
    );

    log(`Sent weekly digest with ${posts.length} stories to topic ${topicId}`);
    return res.json({ ok: true, sent: true, count: posts.length });
  } catch (err) {
    error(`weekly-digest failed: ${err}`);
    return res.json({ ok: false, error: String(err) });
  }
};
