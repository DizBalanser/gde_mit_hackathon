import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { makeCall } from '@/lib/twilio';

export async function GET() {
  const now = new Date();
  const hour = now.getUTCHours();
  const minute = now.getUTCMinutes();

  const usersSnap = await db.collection('users')
    .where('preferredCallUTCHour', '==', hour)
    .where('preferredCallUTCMinute', '==', minute)
    .get();

  if (usersSnap.empty) {
    return NextResponse.json({ called: 0 });
  }

  const results = await Promise.allSettled(
    usersSnap.docs.map(async (doc) => {
      const user = doc.data();
      if (!user.phoneNumber) return null;

      const callSid = await makeCall(user.phoneNumber as string, doc.id);

      await db.collection('users').doc(doc.id).collection('calls').doc(callSid).set({
        callSid,
        startedAt: new Date(),
        status: 'initiated',
        transcript: '',
        scheduledCall: true,
      });

      return callSid;
    })
  );

  const succeeded = results.filter((r) => r.status === 'fulfilled').length;
  return NextResponse.json({ called: succeeded, total: usersSnap.size });
}
