import { NextRequest, NextResponse } from 'next/server';
import { makeCall } from '@/lib/twilio';
import { db } from '@/lib/firebase-admin';

export async function POST(req: NextRequest) {
  const { userId, phoneNumber } = await req.json();

  if (!userId || !phoneNumber) {
    return NextResponse.json({ error: 'userId and phoneNumber required' }, { status: 400 });
  }

  const callSid = await makeCall(phoneNumber, userId);

  await db.collection('users').doc(userId).collection('calls').doc(callSid).set({
    callSid,
    startedAt: new Date(),
    status: 'initiated',
    transcript: '',
  });

  return NextResponse.json({ callSid });
}
