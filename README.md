# App Idea Architecture Advisor

Describe your app idea and receive a comprehensive, step-by-step architecture plan — including apps, AI models, agents, skills, databases, and infrastructure.

## How It Works

1. You provide an app idea (description, target users, and optional features).
2. Local **skills** analyze the idea to identify required components across multiple domains (frontend, backend, AI, databases, infrastructure).
3. An **AI agent** powered by GPT-4o synthesizes the skill results into a detailed, ordered implementation plan.
4. You receive a complete architecture document.

## Project Structure

```
.
├── app.py          # FastAPI REST API
├── cli.py          # Interactive command-line interface
├── agent.py        # Orchestrator agent — runs skills + calls OpenAI
├── models.py       # Pydantic data models (input & output schemas)
├── skills/
│   └── __init__.py # Skill functions for frontend, backend, AI, DB, infra analysis
├── requirements.txt
└── .env.example
```

## Setup

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env and add your OpenAI API key
```

Or export the key directly:

```bash
export OPENAI_API_KEY=your-openai-api-key-here
```

## Usage

### CLI (interactive)

```bash
python cli.py
```

Example session:

```
What is your app idea?
> A platform where users can upload photos and an AI automatically organizes them by people, places, and events, and lets users search their library with natural language.

Who are the target users? (press Enter to skip)
> Families and photography enthusiasts

List key features separated by commas (press Enter to skip)
> photo upload, face recognition, location tagging, natural language search, shared albums
```

### REST API

Start the server:

```bash
uvicorn app:app --reload
```

Then POST your idea to `http://localhost:8000/architecture`:

```bash
curl -X POST http://localhost:8000/architecture \
  -H "Content-Type: application/json" \
  -d '{
    "description": "A platform where users upload photos and AI organizes them",
    "target_users": "Families and photographers",
    "key_features": ["photo upload", "face recognition", "natural language search"]
  }'
```

Interactive API docs are available at `http://localhost:8000/docs`.

## Architecture Response

The response includes:

| Field | Description |
|---|---|
| `app_name` | Suggested name for the app |
| `summary` | High-level description |
| `apps` | Frontend and backend services with technology recommendations |
| `ai_models` | AI/ML models needed (e.g., vision, language, embedding) |
| `agents` | Autonomous agents and their responsibilities |
| `skills` | Individual capabilities used by agents |
| `databases` | Database types and technology suggestions |
| `infrastructure` | Cloud services, CI/CD, monitoring, auth, etc. |
| `implementation_steps` | Ordered, actionable build plan with deliverables |
| `estimated_complexity` | `low`, `medium`, or `high` |
| `notes` | Any important caveats or recommendations |
