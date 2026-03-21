"""
App Idea Architecture Advisor — FastAPI Application

Endpoints:
  POST /architecture  — Submit an app idea and receive a full architecture plan
  GET  /health        — Health check
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from agent import generate_architecture
from models import AppIdea, ArchitectureResponse

app = FastAPI(
    title="App Idea Architecture Advisor",
    description=(
        "Describe your app idea and receive a comprehensive, step-by-step "
        "architecture plan including apps, AI models, agents, skills, databases, "
        "and infrastructure."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/architecture", response_model=ArchitectureResponse)
def create_architecture(idea: AppIdea):
    """
    Submit an app idea and receive a full architecture plan.

    - **description**: What is the app? What problem does it solve?
    - **target_users** *(optional)*: Who will use the app?
    - **key_features** *(optional)*: List the main features you want.
    """
    try:
        result = generate_architecture(idea)
    except EnvironmentError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Architecture generation failed: {exc}")
    return result
