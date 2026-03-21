"""
Skills for analyzing different aspects of an app architecture.
Each skill analyzes a specific domain and returns structured information.
"""

from typing import List, Dict, Any


def analyze_frontend(idea: str, features: List[str]) -> Dict[str, Any]:
    """Determine what frontend apps are needed based on the idea."""
    platforms = []
    technologies = []

    idea_lower = idea.lower()
    features_text = " ".join(features).lower() if features else ""

    if any(word in idea_lower + features_text for word in ["mobile", "ios", "android", "phone", "mobile app"]):
        platforms.append({
            "name": "Mobile App",
            "type": "mobile app",
            "description": "Native or cross-platform mobile application",
            "technologies": ["React Native", "Flutter", "Expo"],
        })
    if any(word in idea_lower + features_text for word in ["web", "browser", "website", "dashboard", "portal"]):
        platforms.append({
            "name": "Web App",
            "type": "web app",
            "description": "Browser-based user interface",
            "technologies": ["React", "Next.js", "TypeScript", "Tailwind CSS"],
        })
    if not platforms:
        platforms.append({
            "name": "Web App",
            "type": "web app",
            "description": "Browser-based user interface",
            "technologies": ["React", "Next.js", "TypeScript", "Tailwind CSS"],
        })

    return {"platforms": platforms}


def analyze_backend(idea: str, features: List[str]) -> Dict[str, Any]:
    """Determine what backend services are needed."""
    services = []
    idea_lower = idea.lower()
    features_text = " ".join(features).lower() if features else ""

    services.append({
        "name": "Core API",
        "type": "REST API",
        "description": "Main backend service handling business logic and data access",
        "technologies": ["FastAPI", "Python", "Pydantic"],
    })

    if any(word in idea_lower + features_text for word in ["real-time", "realtime", "chat", "notification", "live"]):
        services.append({
            "name": "WebSocket Server",
            "type": "real-time service",
            "description": "Handles real-time communication between clients",
            "technologies": ["FastAPI WebSockets", "Socket.IO", "Redis Pub/Sub"],
        })

    if any(word in idea_lower + features_text for word in ["queue", "task", "background", "async", "worker"]):
        services.append({
            "name": "Task Queue",
            "type": "background worker",
            "description": "Processes background jobs and asynchronous tasks",
            "technologies": ["Celery", "Redis", "RQ"],
        })

    return {"services": services}


def analyze_ai_components(idea: str, features: List[str]) -> Dict[str, Any]:
    """Determine what AI models and agents are needed."""
    models = []
    agents = []
    skills = []

    idea_lower = idea.lower()
    features_text = " ".join(features).lower() if features else ""
    combined = idea_lower + " " + features_text

    if any(word in combined for word in ["chat", "conversation", "assistant", "answer", "question", "nlp", "language"]):
        models.append({
            "name": "Language Model",
            "purpose": "Natural language understanding and generation",
            "suggested_model": "GPT-4o / Claude 3.5 Sonnet",
            "notes": "Used for conversational interactions and text generation",
        })
        agents.append({
            "name": "Conversation Agent",
            "role": "Handles user conversations and routes requests",
            "skills": ["intent_detection", "response_generation", "context_management"],
            "tools": ["LLM", "memory_store", "knowledge_base"],
        })
        skills.extend([
            {
                "name": "intent_detection",
                "description": "Identifies what the user is trying to do",
                "used_by": ["Conversation Agent"],
            },
            {
                "name": "response_generation",
                "description": "Generates natural language responses",
                "used_by": ["Conversation Agent"],
            },
            {
                "name": "context_management",
                "description": "Maintains conversation history and context",
                "used_by": ["Conversation Agent"],
            },
        ])

    if any(word in combined for word in ["image", "photo", "vision", "visual", "picture", "camera"]):
        models.append({
            "name": "Vision Model",
            "purpose": "Image understanding and analysis",
            "suggested_model": "GPT-4o Vision / Claude 3.5 Sonnet Vision",
            "notes": "Used for processing and understanding images",
        })
        agents.append({
            "name": "Vision Agent",
            "role": "Analyzes and interprets visual content",
            "skills": ["image_classification", "object_detection", "image_captioning"],
            "tools": ["vision_model", "image_storage"],
        })
        skills.extend([
            {
                "name": "image_classification",
                "description": "Categorizes images into predefined classes",
                "used_by": ["Vision Agent"],
            },
            {
                "name": "object_detection",
                "description": "Identifies and locates objects in images",
                "used_by": ["Vision Agent"],
            },
        ])

    if any(word in combined for word in ["recommend", "suggestion", "personalize", "similar", "preference"]):
        models.append({
            "name": "Recommendation Model",
            "purpose": "Personalized content and item recommendations",
            "suggested_model": "Collaborative Filtering / Embedding-based retrieval",
            "notes": "Learns user preferences to surface relevant content",
        })
        agents.append({
            "name": "Recommendation Agent",
            "role": "Generates personalized recommendations for users",
            "skills": ["user_profiling", "similarity_search", "ranking"],
            "tools": ["embedding_model", "vector_db", "user_history"],
        })
        skills.extend([
            {
                "name": "user_profiling",
                "description": "Builds a model of user preferences from interactions",
                "used_by": ["Recommendation Agent"],
            },
            {
                "name": "similarity_search",
                "description": "Finds similar items using vector embeddings",
                "used_by": ["Recommendation Agent"],
            },
        ])

    if any(word in combined for word in ["search", "retrieval", "find", "lookup", "query", "rag", "knowledge"]):
        models.append({
            "name": "Embedding Model",
            "purpose": "Semantic search and document retrieval",
            "suggested_model": "text-embedding-3-small / Sentence-BERT",
            "notes": "Converts text into vectors for semantic search",
        })
        agents.append({
            "name": "Retrieval Agent",
            "role": "Finds relevant information from the knowledge base",
            "skills": ["query_expansion", "semantic_search", "re_ranking"],
            "tools": ["embedding_model", "vector_db", "document_store"],
        })
        skills.extend([
            {
                "name": "semantic_search",
                "description": "Searches for semantically similar content using embeddings",
                "used_by": ["Retrieval Agent"],
            },
            {
                "name": "re_ranking",
                "description": "Re-orders results by relevance",
                "used_by": ["Retrieval Agent"],
            },
        ])

    if not models:
        models.append({
            "name": "Language Model",
            "purpose": "Core intelligence and decision making",
            "suggested_model": "GPT-4o / Claude 3.5 Sonnet",
            "notes": "Main AI model driving the application logic",
        })
        agents.append({
            "name": "Orchestrator Agent",
            "role": "Coordinates tasks and delegates to specialized sub-agents",
            "skills": ["task_planning", "tool_use", "result_synthesis"],
            "tools": ["LLM", "sub_agents", "tool_registry"],
        })
        skills.extend([
            {
                "name": "task_planning",
                "description": "Breaks down complex goals into actionable steps",
                "used_by": ["Orchestrator Agent"],
            },
            {
                "name": "tool_use",
                "description": "Selects and invokes the right tools for a task",
                "used_by": ["Orchestrator Agent"],
            },
        ])

    return {"models": models, "agents": agents, "skills": skills}


def analyze_database(idea: str, features: List[str]) -> Dict[str, Any]:
    """Determine what databases are needed."""
    databases = []
    idea_lower = idea.lower()
    features_text = " ".join(features).lower() if features else ""
    combined = idea_lower + " " + features_text

    databases.append({
        "type": "relational",
        "suggested_technology": "PostgreSQL",
        "main_entities": ["Users", "Sessions", "Events"],
        "notes": "Primary structured data store for user and application data",
    })

    if any(word in combined for word in ["search", "retrieval", "semantic", "embedding", "vector", "similarity", "rag", "knowledge"]):
        databases.append({
            "type": "vector",
            "suggested_technology": "Pinecone / pgvector / ChromaDB",
            "main_entities": ["Document Embeddings", "User Preference Vectors"],
            "notes": "Stores vector embeddings for semantic search and retrieval",
        })

    if any(word in combined for word in ["session", "cache", "real-time", "fast", "temporary", "queue"]):
        databases.append({
            "type": "in-memory",
            "suggested_technology": "Redis",
            "main_entities": ["Sessions", "Caches", "Queues"],
            "notes": "High-speed caching, session management, and message queuing",
        })

    if any(word in combined for word in ["document", "content", "flexible", "unstructured", "nosql"]):
        databases.append({
            "type": "document",
            "suggested_technology": "MongoDB",
            "main_entities": ["Documents", "Content", "Logs"],
            "notes": "Flexible schema storage for unstructured or semi-structured data",
        })

    return {"databases": databases}


def analyze_infrastructure(idea: str, features: List[str]) -> Dict[str, Any]:
    """Determine what infrastructure components are needed."""
    components = [
        {
            "name": "Cloud Hosting",
            "purpose": "Host and scale all application services",
            "suggested_service": "AWS / GCP / Azure",
        },
        {
            "name": "Container Orchestration",
            "purpose": "Deploy and manage microservices",
            "suggested_service": "Kubernetes (EKS/GKE) or Docker Compose (small scale)",
        },
        {
            "name": "CI/CD Pipeline",
            "purpose": "Automate testing and deployment",
            "suggested_service": "GitHub Actions / GitLab CI",
        },
        {
            "name": "Monitoring & Logging",
            "purpose": "Track performance, errors, and usage metrics",
            "suggested_service": "Datadog / Grafana + Prometheus / CloudWatch",
        },
        {
            "name": "Secret Management",
            "purpose": "Securely store API keys and credentials",
            "suggested_service": "AWS Secrets Manager / HashiCorp Vault",
        },
    ]

    idea_lower = idea.lower()
    features_text = " ".join(features).lower() if features else ""
    combined = idea_lower + " " + features_text

    if any(word in combined for word in ["file", "upload", "image", "video", "media", "storage", "document"]):
        components.append({
            "name": "Object Storage",
            "purpose": "Store user-uploaded files and media",
            "suggested_service": "AWS S3 / Google Cloud Storage",
        })

    if any(word in combined for word in ["email", "notification", "sms", "message", "alert"]):
        components.append({
            "name": "Notification Service",
            "purpose": "Send emails, SMS, and push notifications",
            "suggested_service": "SendGrid / Twilio / AWS SES",
        })

    if any(word in combined for word in ["payment", "billing", "subscription", "purchase", "buy"]):
        components.append({
            "name": "Payment Gateway",
            "purpose": "Handle payments and subscriptions",
            "suggested_service": "Stripe / PayPal",
        })

    if any(word in combined for word in ["auth", "login", "user", "signup", "oauth", "sso"]):
        components.append({
            "name": "Authentication Service",
            "purpose": "Manage user identity and access control",
            "suggested_service": "Auth0 / AWS Cognito / Supabase Auth",
        })

    return {"infrastructure": components}
