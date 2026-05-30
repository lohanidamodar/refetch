/**
 * subscribe Appwrite Function
 *
 * Execution: called by the app (authenticated with the user's JWT) right after
 * it registers a push target. Subscribes all of the calling user's push targets
 * to the app's notification topics so they receive digest/broadcast messages.
 *
 * The calling user is read from the `x-appwrite-user-id` header that Appwrite
 * injects for authenticated executions.
 *
 * Required env:
 *   APPWRITE_FUNCTION_API_ENDPOINT, APPWRITE_FUNCTION_PROJECT_ID  (auto-injected)
 *   APPWRITE_API_KEY
 *   DIGEST_TOPIC_ID
 *   REPLIES_TOPIC_ID           (optional)
 */
import { Client, Users, Messaging, ID } from 'node-appwrite';

export default async ({ req, res, log, error }) => {
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) {
    return res.json({ ok: false, reason: 'unauthenticated' }, 401);
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const users = new Users(client);
  const messaging = new Messaging(client);

  const topicIds = [process.env.DIGEST_TOPIC_ID, process.env.REPLIES_TOPIC_ID]
    .filter(Boolean);
  if (topicIds.length === 0) {
    return res.json({ ok: true, subscribed: 0, reason: 'no topics configured' });
  }

  try {
    const result = await users.listTargets(userId);
    const pushTargets = (result.targets ?? []).filter(
      (t) => t.providerType === 'push',
    );

    let subscribed = 0;
    for (const target of pushTargets) {
      for (const topicId of topicIds) {
        await messaging
          .createSubscriber(topicId, ID.unique(), target.$id)
          .then(() => subscribed++)
          .catch(() => {
            // Already subscribed (conflict) — ignore.
          });
      }
    }

    log(`Subscribed ${subscribed} (target, topic) pairs for user ${userId}`);
    return res.json({ ok: true, subscribed });
  } catch (err) {
    error(`subscribe failed: ${err}`);
    return res.json({ ok: false, error: String(err) });
  }
};
