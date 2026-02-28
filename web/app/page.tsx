import { db } from '@/lib/firebase-admin';
import UserCard from './components/UserCard';

interface UserProfile {
  uid: string;
  name: string;
  phoneNumber: string;
  preferredCallUTCHour: number;
  preferredCallUTCMinute: number;
  timezone: string;
  lastEntry?: string;
}

async function getUsers(): Promise<UserProfile[]> {
  const snapshot = await db.collection('users').orderBy('updatedAt', 'desc').get();
  return snapshot.docs.map((doc) => ({
    uid: doc.id,
    name: (doc.data().name as string) ?? '',
    phoneNumber: (doc.data().phoneNumber as string) ?? '',
    preferredCallUTCHour: (doc.data().preferredCallUTCHour as number) ?? 0,
    preferredCallUTCMinute: (doc.data().preferredCallUTCMinute as number) ?? 0,
    timezone: (doc.data().timezone as string) ?? 'UTC',
    lastEntry: undefined,
  }));
}

export const dynamic = 'force-dynamic';

export default async function HomePage() {
  let users: UserProfile[] = [];
  let error: string | null = null;

  try {
    users = await getUsers();
  } catch (e) {
    error = (e as Error).message;
  }

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      {/* Header */}
      <header className="border-b border-zinc-200 bg-white dark:bg-zinc-900 dark:border-zinc-800">
        <div className="mx-auto max-w-4xl px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-purple-600">
              <span className="text-white text-sm font-bold">A</span>
            </div>
            <div>
              <h1 className="text-base font-semibold text-zinc-900 dark:text-white">Aura Admin</h1>
              <p className="text-xs text-zinc-500">Voice call dashboard</p>
            </div>
          </div>
          <span className="rounded-full bg-purple-50 px-3 py-1 text-xs font-medium text-purple-700 dark:bg-purple-900/30 dark:text-purple-300">
            {users.length} user{users.length !== 1 ? 's' : ''}
          </span>
        </div>
      </header>

      {/* Main */}
      <main className="mx-auto max-w-4xl px-4 py-8">
        {error && (
          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
            <strong>Firebase error:</strong> {error}. Check your environment variables.
          </div>
        )}

        {users.length === 0 && !error ? (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <div className="mb-4 text-5xl">📱</div>
            <p className="text-lg font-medium text-zinc-700 dark:text-zinc-300">No users yet</p>
            <p className="mt-1 text-sm text-zinc-500">
              Users will appear here after they open the iOS app and set their phone number.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            <p className="text-sm text-zinc-500 mb-4">
              Click <strong>Make a Call</strong> to immediately call a user. Daily calls are scheduled automatically based on each user&apos;s preferred time.
            </p>
            {users.map((user) => (
              <UserCard key={user.uid} user={user} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
