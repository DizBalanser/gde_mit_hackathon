# Besh: Proactive AI Voice Triage for Post-AMI Care

**Elevator Pitch:** 20% of post-heart attack patients are readmitted within 30 days.  
**Besh** is a proactive AI voice agent that calls patients, conducts a 60-second clinical triage, and sends structured SOAP notes to doctors.  
**Zero apps required.**

---

## Inspiration

The digital health market is flooded with passive tracking apps. But we realized a hard truth: expecting a 70-year-old post-heart attack patient with low digital literacy to download an iOS app, navigate menus, and log symptoms daily is a clinical fantasy.

The care gap between hospital discharge and the 30-day follow-up is where patients slip through the cracks and hospital readmission penalties skyrocket. We wanted to kill the "blank text box" and meet patients exactly where they are: on a simple phone call.

## What It Does

Besh is a proactive, automated voice triage system that bridges the gap between patient reality and clinical oversight.

- **Proactive check-ins**: Instead of waiting for data, Besh initiates a daily phone call to the patient.
- **Dynamic interrogation**: Using Azure OpenAI, the agent does not ask generic questions. It reviews yesterday's data and asks targeted prompts (for example, "Yesterday your ankles were swollen, is the swelling worse today?").
- **Deterministic risk scoring**: We decoupled medical decision-making from the LLM. The AI only extracts data; a hardcoded deterministic rule engine flags Red, Yellow, or Green risk states based on clinical guidelines.
- **Clinician dashboard**: Care teams receive a prioritized patient list and structured AI-generated SOAP notes, cutting noise and surfacing immediate risks.

## How We Built It

We built Besh with a focus on speed, compliance, and clinical safety:

- **Telephony layer**: Twilio voice webhooks handle outbound and inbound call flow.
- **AI + parsing (Azure stack)**: Azure Speech-to-Text transcribes voice in near real time. The transcript is sent to Azure OpenAI (GPT-4o) with strict system prompts that output a clean JSON object (symptoms, severity, medication adherence).
- **Backend**: Node.js + Express orchestrates APIs and runs the deterministic risk engine.
- **Frontend**: Vanilla JS + HTML dashboard designed for care coordinator workflows, transforming extracted JSON into readable SOAP-format summaries.

## Challenges We Ran Into

1. **Voice latency**: Chaining Twilio, Azure Speech, and Azure OpenAI initially created about a 5-second response delay, which confused users. We optimized prompts, tightened token limits, and used streaming to reduce latency under 2 seconds.
2. **AI hallucinations**: Early iterations sometimes generated medical advice. We tightened prompts so the model remains strictly in *data extraction* mode and does not produce diagnostic output.
3. **The pivot**: We originally built a complex iOS diary app. Midway, we realized it alienated our target demographic (elderly cardiac patients). We made the hard call to pivot toward a voice-first telephony experience.

## Accomplishments We're Proud Of

- **Zero-friction UX**: No app install, no password memory, no typing burden on small screens.
- **SaMD boundary awareness**: LLM handles extraction only; deterministic rules handle risk scoring, aligning with Software as a Medical Device boundary principles.
- **Bulletproof demo mode**: A backend bypass supports repeatable clinical data simulations without relying on live API quotas during demos.

## What We Learned

In healthcare technology, AI must be strictly bounded. LLMs are excellent at parsing unstructured patient narratives into structured JSON, but unsafe if allowed to assess clinical risk directly.  
The best user interface for a sick patient is often **no interface at all**.

---

## Repository Structure

```text
.
├── ios/   # Legacy iOS prototype (pre-pivot)
└── web/   # Voice triage backend + dashboard (active demo implementation)
```

## Quick Start (Web)

From the `web/` directory:

```bash
pnpm install
pnpm dev
```

This starts the app with the custom Node server (`server.js`).

## Core Principles

- Keep patient interaction simple and phone-first.
- Keep AI constrained to extraction, not diagnosis.
- Keep risk logic deterministic, transparent, and auditable.
- Keep clinician output structured, concise, and actionable.
