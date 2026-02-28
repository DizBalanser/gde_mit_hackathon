import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const userId = searchParams.get('userId') ?? '';
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL ?? '';
  const wsHost = new URL(baseUrl).host;

  const twiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Connect>
    <Stream url="wss://${wsHost}/api/twilio/stream?userId=${encodeURIComponent(userId)}" />
  </Connect>
</Response>`;

  return new NextResponse(twiml, {
    headers: { 'Content-Type': 'text/xml' },
  });
}
