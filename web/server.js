'use strict';

require('dotenv').config({ path: '.env.local' });

const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');
const { WebSocketServer, WebSocket } = require('ws');
const admin = require('firebase-admin');

// ─── Firebase Admin (singleton init) ─────────────────────────────────────────
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}
const firestoreDb = admin.firestore();

// ─── μ-law codec ──────────────────────────────────────────────────────────────
// Decode table: 8-bit μ-law byte → 16-bit signed PCM sample
const MULAW_DECODE = new Int16Array(256);
(function buildDecodeTable() {
  for (let i = 0; i < 256; i++) {
    let x = ~i & 0xff;
    const sign = x & 0x80;
    const exponent = (x >> 4) & 0x07;
    const mantissa = x & 0x0f;
    let val = ((mantissa << 1) | 0x21) << exponent;
    val -= 33;
    MULAW_DECODE[i] = sign ? -val : val;
  }
})();

function mulawDecode(byte) {
  return MULAW_DECODE[byte & 0xff];
}

function mulawEncode(sample) {
  const BIAS = 33;
  const MAX = 0x1fff;
  sample = Math.max(-32768, Math.min(32767, sample));
  const sign = (sample >> 8) & 0x80;
  if (sign) sample = -sample;
  sample += BIAS;
  if (sample > MAX) sample = MAX;

  let exponent, mantissa;
  if (sample <= 0x3f)       { exponent = 0; mantissa = sample >> 1; }
  else if (sample <= 0x7f)  { exponent = 1; mantissa = (sample - 0x40) >> 1; }
  else if (sample <= 0xff)  { exponent = 2; mantissa = (sample - 0x80) >> 2; }
  else if (sample <= 0x1ff) { exponent = 3; mantissa = (sample - 0x100) >> 3; }
  else if (sample <= 0x3ff) { exponent = 4; mantissa = (sample - 0x200) >> 4; }
  else if (sample <= 0x7ff) { exponent = 5; mantissa = (sample - 0x400) >> 5; }
  else if (sample <= 0xfff) { exponent = 6; mantissa = (sample - 0x800) >> 6; }
  else                       { exponent = 7; mantissa = (sample - 0x1000) >> 7; }

  return (~(sign | (exponent << 4) | mantissa)) & 0xff;
}

// Linear interpolation resampler (PCM16 arrays)
function resample(samples, fromRate, toRate) {
  if (fromRate === toRate) return samples;
  const ratio = fromRate / toRate;
  const outLen = Math.round(samples.length * (toRate / fromRate));
  const out = new Int16Array(outLen);
  for (let i = 0; i < outLen; i++) {
    const pos = i * ratio;
    const idx = Math.floor(pos);
    const frac = pos - idx;
    const s0 = samples[Math.min(idx, samples.length - 1)];
    const s1 = samples[Math.min(idx + 1, samples.length - 1)];
    out[i] = Math.round(s0 + frac * (s1 - s0));
  }
  return out;
}

// ─── Next.js setup ────────────────────────────────────────────────────────────
const dev = process.env.NODE_ENV !== 'production';
const app = next({ dev });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  const server = createServer((req, res) => {
    const parsedUrl = parse(req.url, true);
    handle(req, res, parsedUrl);
  });

  // ─── WebSocket server (same port as HTTP) ──────────────────────────────────
  const wss = new WebSocketServer({ server, path: '/api/twilio/stream' });

  wss.on('connection', (ws, req) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const userId = url.searchParams.get('userId') ?? '';
    console.log(`[WS] New Twilio stream connection — userId: ${userId}`);
    handleTwilioStream(ws, userId);
  });

  const port = process.env.PORT || 3000;
  server.listen(port, () => {
    console.log(`> Ready on http://localhost:${port}`);
    console.log(`> WebSocket listening at ws://localhost:${port}/api/twilio/stream`);
  });
});

// ─── Twilio ↔ OpenAI Realtime bridge ─────────────────────────────────────────
function handleTwilioStream(twilioWs, userId) {
  let streamSid = '';
  let callSid = '';
  const lines = [];

  // Open connection to OpenAI Realtime API
  const openaiWs = new WebSocket(
    'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17',
    {
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        'OpenAI-Beta': 'realtime=v1',
      },
    }
  );

  openaiWs.on('open', () => {
    console.log('[OpenAI] Realtime WebSocket connected');

    // Configure the session
    openaiWs.send(JSON.stringify({
      type: 'session.update',
      session: {
        modalities: ['audio', 'text'],
        instructions: `You are Aura, a friendly AI health assistant making a daily check-in call.
Greet the user warmly and ask the following questions ONE AT A TIME, waiting for each answer:
1. "How are you feeling today on a scale of 1 to 10?"
2. "Do you have any symptoms today — like a headache, nausea, fatigue, or pain? If yes, how severe on a scale of 1 to 10?"
3. "What did you eat today?"
4. "How would you describe your mood today?"
After collecting all answers, say: "Thank you so much! Your responses have been recorded. Have a wonderful day!" and end the conversation.
Be warm, concise, and supportive. Don't repeat questions unnecessarily.`,
        voice: 'alloy',
        input_audio_format: 'pcm16',
        output_audio_format: 'pcm16',
        input_audio_transcription: { model: 'whisper-1' },
        turn_detection: {
          type: 'server_vad',
          threshold: 0.5,
          prefix_padding_ms: 300,
          silence_duration_ms: 800,
        },
      },
    }));

    // Trigger the initial greeting
    openaiWs.send(JSON.stringify({
      type: 'conversation.item.create',
      item: {
        type: 'message',
        role: 'user',
        content: [{ type: 'input_text', text: 'Start the conversation with a greeting.' }],
      },
    }));
    openaiWs.send(JSON.stringify({ type: 'response.create' }));
  });

  // OpenAI → Twilio: convert PCM16 24kHz to μ-law 8kHz and send audio
  openaiWs.on('message', (raw) => {
    try {
      const event = JSON.parse(raw.toString());

      // Stream audio delta back to Twilio
      if (event.type === 'response.audio.delta' && event.delta && streamSid) {
        const pcm24kBuf = Buffer.from(event.delta, 'base64');
        const pcm16 = new Int16Array(pcm24kBuf.buffer, pcm24kBuf.byteOffset, pcm24kBuf.length / 2);
        const pcm8k = resample(pcm16, 24000, 8000);
        const mulawBuf = Buffer.alloc(pcm8k.length);
        for (let i = 0; i < pcm8k.length; i++) {
          mulawBuf[i] = mulawEncode(pcm8k[i]);
        }

        if (twilioWs.readyState === WebSocket.OPEN) {
          twilioWs.send(JSON.stringify({
            event: 'media',
            streamSid,
            media: { payload: mulawBuf.toString('base64') },
          }));
        }
      }

      // Collect transcript lines
      if (event.type === 'conversation.item.completed') {
        const item = event.item;
        if (item?.role === 'assistant') {
          const text = item.content?.find((c) => c.type === 'text')?.text ?? '';
          if (text) lines.push(`Assistant: ${text}`);
        }
        if (item?.role === 'user') {
          const text = item.content?.find(
            (c) => c.type === 'input_text' || c.type === 'input_audio'
          )?.transcript ?? item.content?.find((c) => c.type === 'input_text')?.text ?? '';
          if (text) lines.push(`User: ${text}`);
        }
      }
    } catch (err) {
      console.error('[OpenAI] Parse error:', err);
    }
  });

  openaiWs.on('error', (err) => console.error('[OpenAI] WS error:', err));
  openaiWs.on('close', () => console.log('[OpenAI] WS closed'));

  // Twilio → OpenAI: decode μ-law 8kHz to PCM16 24kHz and forward
  twilioWs.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw.toString());

      if (msg.event === 'start') {
        streamSid = msg.start.streamSid;
        callSid = msg.start.callSid ?? '';
        console.log(`[Twilio] Stream started — streamSid: ${streamSid}, callSid: ${callSid}`);
      }

      if (msg.event === 'media' && openaiWs.readyState === WebSocket.OPEN) {
        const mulawBuf = Buffer.from(msg.media.payload, 'base64');
        const pcm8k = new Int16Array(mulawBuf.length);
        for (let i = 0; i < mulawBuf.length; i++) {
          pcm8k[i] = mulawDecode(mulawBuf[i]);
        }
        const pcm24k = resample(pcm8k, 8000, 24000);
        const outBuf = Buffer.allocUnsafe(pcm24k.length * 2);
        for (let i = 0; i < pcm24k.length; i++) {
          outBuf.writeInt16LE(pcm24k[i], i * 2);
        }

        openaiWs.send(JSON.stringify({
          type: 'input_audio_buffer.append',
          audio: outBuf.toString('base64'),
        }));
      }

      if (msg.event === 'stop') {
        console.log('[Twilio] Stream stopped');
        openaiWs.close();
        saveTranscript(userId, callSid, lines.join('\n'));
      }
    } catch (err) {
      console.error('[Twilio] Parse error:', err);
    }
  });

  twilioWs.on('close', () => {
    console.log('[Twilio] WS closed');
    if (openaiWs.readyState === WebSocket.OPEN) openaiWs.close();
    if (lines.length > 0) saveTranscript(userId, callSid, lines.join('\n'));
  });
}

// ─── Persist call transcript to Firestore ─────────────────────────────────────
async function saveTranscript(userId, callSid, transcript) {
  if (!userId || !transcript) return;
  const docId = callSid || `call_${Date.now()}`;
  try {
    await firestoreDb
      .collection('users').doc(userId)
      .collection('calls').doc(docId)
      .set({ transcript, status: 'completed', endedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    console.log(`[Firestore] Transcript saved for ${userId}/${docId}`);
  } catch (err) {
    console.error('[Firestore] Failed to save transcript:', err);
  }
}
