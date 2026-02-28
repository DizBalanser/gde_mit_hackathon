'use client';

import { useState } from 'react';

interface UserData {
  uid: string;
  name: string;
  phoneNumber: string;
  preferredCallUTCHour: number;
  preferredCallUTCMinute: number;
  timezone: string;
  lastEntry?: string;
}

export default function UserCard({ user }: { user: UserData }) {
  const [state, setState] = useState<'idle' | 'calling' | 'called' | 'error'>('idle');

  const handleCall = async () => {
    setState('calling');
    try {
      const res = await fetch('/api/call', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: user.uid, phoneNumber: user.phoneNumber }),
      });
      if (!res.ok) throw new Error('Call failed');
      setState('called');
    } catch {
      setState('error');
      setTimeout(() => setState('idle'), 3000);
    }
  };

  const utcTime = `${String(user.preferredCallUTCHour).padStart(2, '0')}:${String(user.preferredCallUTCMinute).padStart(2, '0')} UTC`;

  return (
    <div className="flex items-center justify-between rounded-2xl bg-white px-5 py-4 shadow-sm border border-zinc-100">
      {/* Avatar + Info */}
      <div className="flex items-center gap-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100 text-purple-600 font-semibold text-sm">
          {(user.name || 'A')[0].toUpperCase()}
        </div>
        <div>
          <p className="font-medium text-zinc-900">{user.name || 'Anonymous'}</p>
          <p className="text-sm text-zinc-500">{user.phoneNumber || 'No phone set'}</p>
          {user.lastEntry && (
            <p className="mt-0.5 text-xs text-zinc-400 line-clamp-1">Last: {user.lastEntry}</p>
          )}
        </div>
      </div>

      {/* Right side */}
      <div className="flex items-center gap-4">
        <div className="text-right hidden sm:block">
          <p className="text-xs text-zinc-400">Daily call</p>
          <p className="text-sm font-medium text-zinc-600">{utcTime}</p>
        </div>
        <button
          onClick={handleCall}
          disabled={state === 'calling' || state === 'called' || !user.phoneNumber}
          className={`rounded-xl px-4 py-2 text-sm font-medium transition-all
            ${state === 'called'
              ? 'bg-green-100 text-green-700'
              : state === 'error'
              ? 'bg-red-100 text-red-600'
              : state === 'calling'
              ? 'bg-purple-50 text-purple-400 cursor-wait'
              : !user.phoneNumber
              ? 'bg-zinc-100 text-zinc-400 cursor-not-allowed'
              : 'bg-purple-600 text-white hover:bg-purple-700 active:scale-95'
            }`}
        >
          {state === 'called' ? '✓ Called' : state === 'calling' ? 'Calling…' : state === 'error' ? 'Failed' : 'Make a Call'}
        </button>
      </div>
    </div>
  );
}
