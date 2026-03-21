from pydantic import BaseModel, Field
from typing import List, Optional


class AppIdea(BaseModel):
    description: str = Field(..., description="A description of the app idea")
    target_users: Optional[str] = Field(None, description="Who will use the app")
    key_features: Optional[List[str]] = Field(None, description="Key features of the app")


class AppComponent(BaseModel):
    name: str
    type: str  # e.g. "web app", "mobile app", "API", "database", etc.
    description: str
    technologies: List[str]


class AIModel(BaseModel):
    name: str
    purpose: str
    suggested_model: str
    notes: Optional[str] = None


class Agent(BaseModel):
    name: str
    role: str
    skills: List[str]
    tools: List[str]


class Skill(BaseModel):
    name: str
    description: str
    used_by: List[str]  # which agents or components use this skill


class DatabaseDesign(BaseModel):
    type: str  # e.g. "relational", "NoSQL", "vector"
    suggested_technology: str
    main_entities: List[str]
    notes: Optional[str] = None


class InfrastructureComponent(BaseModel):
    name: str
    purpose: str
    suggested_service: str


class ArchitectureStep(BaseModel):
    step_number: int
    title: str
    description: str
    deliverables: List[str]


class ArchitectureResponse(BaseModel):
    app_name: str
    summary: str
    apps: List[AppComponent]
    ai_models: List[AIModel]
    agents: List[Agent]
    skills: List[Skill]
    databases: List[DatabaseDesign]
    infrastructure: List[InfrastructureComponent]
    implementation_steps: List[ArchitectureStep]
    estimated_complexity: str  # "low", "medium", "high"
    notes: Optional[str] = None
