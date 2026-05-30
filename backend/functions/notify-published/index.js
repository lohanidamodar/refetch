/**
 * notify-published Appwrite Function
 *
 * Trigger: event `databases.*.collections.<POSTS_COLLECTION_ID>.documents.*.update`
 *
 * When a post transitions to `enhanced = true` (AI processing finished and it is
 * now live), notifies the post's author. Guards against re-notifying on
 * unrelated updates by checking that the post is enhanced.
 *
 * NOTE: Appwrite update events don't include the previous document state, so
 * this fires on any update where `enhanced` is true. To send exactly once,
 * either (a) only enable this trigger and have the enhancement step be the only
 * writer that sets `enhanced=true`, or (b) add a `notifiedPublished` boolean to
 * the posts collection and set it here. Option (b) is implemented below and is
 * a no-op until that attribute exists.
 *
 * Required env:
 *   APPWRITE_FUNCTION_API_ENDPOINT, APPWRITE_FUNCTION_PROJECT_ID  (auto-injected)
 *   APPWRITE_API_KEY
 *   APPWRITE_DATABASE_ID, APPWRITE_POSTS_COLLECTION_ID
 */
import { Client, TablesDB, Messaging, ID } from 'node-appwrite';

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const tablesDB = new TablesDB(client);
  const messaging = new Messaging(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const postsCollectionId = process.env.APPWRITE_POSTS_COLLECTION_ID;

  const post = req.bodyJson ?? safeParse(req.bodyRaw ?? req.body);
  if (!post || !post.$id) {
    return res.json({ ok: false, reason: 'no post payload' });
  }

  if (post.enhanced !== true || !post.userId) {
    return res.json({ ok: true, sent: false, reason: 'not enhanced' });
  }

  // Send-once guard (no-op if the attribute isn't present in the schema).
  if (post.notifiedPublished === true) {
    return res.json({ ok: true, sent: false, reason: 'already notified' });
  }

  try {
    await messaging.createPush(
      ID.unique(),
      'Your post is live on Refetch',
      truncate(post.title || 'Your submission has been published.', 140),
      [],
      [post.userId],
      [],
      { postId: post.$id, type: 'published' },
    );

    await tablesDB
      .updateRow(databaseId, postsCollectionId, post.$id, {
        notifiedPublished: true,
      })
      .catch(() => {
        log('notifiedPublished attribute not present; skipping send-once flag.');
      });

    log(`Sent published notification to user ${post.userId}`);
    return res.json({ ok: true, sent: true });
  } catch (err) {
    error(`notify-published failed: ${err}`);
    return res.json({ ok: false, error: String(err) });
  }
};

function truncate(text, max) {
  const clean = String(text).replace(/\s+/g, ' ').trim();
  return clean.length <= max ? clean : `${clean.slice(0, max - 1)}…`;
}

function safeParse(value) {
  if (!value) return null;
  if (typeof value === 'object') return value;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}
