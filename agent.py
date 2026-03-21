"""
Architecture Advisor Agent

This agent takes an app idea and uses OpenAI to generate a comprehensive
step-by-step architecture plan, combining LLM intelligence with structured
skill-based analysis.
"""

import json
import os
from typing import List, Optional

from openai import OpenAI

from models import (
    AppComponent,
    Agent,
    AIModel,
    AppIdea,
    ArchitectureResponse,
    ArchitectureStep,
    DatabaseDesign,
    InfrastructureComponent,
    Skill,
)
from skills import (
    analyze_ai_components,
    analyze_backend,
    analyze_database,
    analyze_frontend,
    analyze_infrastructure,
)

SYSTEM_PROMPT = """You are an expert software architect and AI systems designer.
Given an app idea, you provide a comprehensive, actionable architecture plan.
You will be given structured analysis from specialized skills and must synthesize 
a complete architecture including:
- A clear app name
- A concise summary
- Step-by-step implementation plan (5-8 steps)
- Estimated complexity (low, medium, or high)
- Any important notes or caveats

Always be specific about technology choices and explain WHY each component is chosen.
Return your response ONLY as valid JSON matching the specified schema."""


def build_user_prompt(idea: AppIdea, skill_results: dict) -> str:
    return f"""Here is the app idea:

Description: {idea.description}
Target Users: {idea.target_users or "General public"}
Key Features: {", ".join(idea.key_features) if idea.key_features else "Not specified"}

Skill analysis results:
{json.dumps(skill_results, indent=2)}

Based on the above, generate a complete architecture plan as JSON with this exact structure:
{{
  "app_name": "string",
  "summary": "string",
  "implementation_steps": [
    {{
      "step_number": 1,
      "title": "string",
      "description": "string",
      "deliverables": ["string"]
    }}
  ],
  "estimated_complexity": "low|medium|high",
  "notes": "string or null"
}}

The skill analysis already provides apps, ai_models, agents, skills, databases, and infrastructure.
Focus your JSON output on: app_name, summary, implementation_steps, estimated_complexity, and notes.
Make the implementation_steps detailed, actionable, and in the correct order."""


def run_skills(idea: AppIdea) -> dict:
    """Run all skill analyzers and combine their results."""
    features = idea.key_features or []

    frontend = analyze_frontend(idea.description, features)
    backend = analyze_backend(idea.description, features)
    ai = analyze_ai_components(idea.description, features)
    db = analyze_database(idea.description, features)
    infra = analyze_infrastructure(idea.description, features)

    return {
        "apps": frontend["platforms"] + backend["services"],
        "ai_models": ai["models"],
        "agents": ai["agents"],
        "skills": ai["skills"],
        "databases": db["databases"],
        "infrastructure": infra["infrastructure"],
    }


def generate_architecture(idea: AppIdea) -> ArchitectureResponse:
    """
    Main agent function: runs all skills, calls OpenAI to synthesize
    the implementation plan, and returns a full ArchitectureResponse.
    """
    skill_results = run_skills(idea)

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise EnvironmentError(
            "OPENAI_API_KEY environment variable is not set. "
            "Please set it before running the agent."
        )

    client = OpenAI(api_key=api_key)

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": build_user_prompt(idea, skill_results)},
        ],
        response_format={"type": "json_object"},
        temperature=0.3,
    )

    llm_output = json.loads(response.choices[0].message.content)

    apps = [AppComponent(**a) for a in skill_results["apps"]]
    ai_models = [AIModel(**m) for m in skill_results["ai_models"]]
    agents = [Agent(**a) for a in skill_results["agents"]]
    skills = [Skill(**s) for s in skill_results["skills"]]
    databases = [DatabaseDesign(**d) for d in skill_results["databases"]]
    infrastructure = [InfrastructureComponent(**i) for i in skill_results["infrastructure"]]
    implementation_steps = [ArchitectureStep(**s) for s in llm_output["implementation_steps"]]

    return ArchitectureResponse(
        app_name=llm_output["app_name"],
        summary=llm_output["summary"],
        apps=apps,
        ai_models=ai_models,
        agents=agents,
        skills=skills,
        databases=databases,
        infrastructure=infrastructure,
        implementation_steps=implementation_steps,
        estimated_complexity=llm_output["estimated_complexity"],
        notes=llm_output.get("notes"),
    )
