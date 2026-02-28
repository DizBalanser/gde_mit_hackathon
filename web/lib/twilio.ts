import twilio from 'twilio';

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID!,
  process.env.TWILIO_AUTH_TOKEN!
);

export async function makeCall(toPhone: string, userId: string): Promise<string> {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL;
  const call = await client.calls.create({
    to: toPhone,
    from: process.env.TWILIO_PHONE_NUMBER!,
    url: `${baseUrl}/api/twilio/voice?userId=${encodeURIComponent(userId)}`,
    method: 'POST',
  });
  return call.sid;
}
