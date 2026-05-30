/**
 * notify-reply Appwrite Function
 *
 * Trigger: event `databases.*.collections.<COMMENTS_COLLECTION_ID>.documents.*.create`
 *
 * When a comment is created, notifies the author of the parent comment (for a
 * reply) or the post author (for a top-level comment) via Appwrite Messaging
 * push. Self-replies are skipped.
 *
 * Required env:
 *   APPWRITE_FUNCTION_API_ENDPOINT, APPWRITE_FUNCTION_PROJECT_ID  (auto-injected)
 *   APPWRITE_API_KEY
 *   APPWRITE_DATABASE_ID, APPWRITE_POSTS_COLLECTION_ID, APPWRITE_COMMENTS_COLLECTION_ID
 */
import { Client, TablesDB, Messaging, ID } from 'node-appwrite';
import { resolveNotifyTarget } from './resolve_target.mjs';

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const tablesDB = new TablesDB(client);
  const messaging = new Messaging(client);

  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const postsCollectionId = process.env.APPWRITE_POSTS_COLLECTION_ID;
  const commentsCollectionId = process.env.APPWRITE_COMMENTS_COLLECTION_ID;

  // The triggering comment document.
  const comment = req.bodyJson ?? safeParse(req.bodyRaw ?? req.body);
  if (!comment || !comment.$id) {
    return res.json({ ok: false, reason: 'no comment payload' });
  }

  try {
    const parentComment = comment.replyId
      ? await tablesDB
          .getRow(databaseId, commentsCollectionId, comment.replyId)
          .catch(() => null)
      : null;

    const post = comment.postId
      ? await tablesDB
          .getRow(databaseId, postsCollectionId, comment.postId)
          .catch(() => null)
      : null;

    const target = resolveNotifyTarget({ comment, parentComment, post });
    if (!target) {
      return res.json({ ok: true, sent: false, reason: 'no recipient' });
    }

    await messaging.createPush(
      ID.unique(),
      target.title,
      target.body,
      [], // topics
      [target.userId], // users
      [], // targets
      { postId: target.postId, type: 'reply' }, // data
    );

    log(`Sent reply notification to user ${target.userId}`);
    return res.json({ ok: true, sent: true });
  } catch (err) {
    error(`notify-reply failed: ${err}`);
    return res.json({ ok: false, error: String(err) });
  }
};

function safeParse(value) {
  if (!value) return null;
  if (typeof value === 'object') return value;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}
