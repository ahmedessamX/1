#!/usr/bin/env python3
"""
CLI interface for the App Idea Architecture Advisor.

Usage:
    python cli.py

The CLI will prompt you for your app idea and display a formatted architecture plan.
"""

import json
import os
import sys

from agent import generate_architecture
from models import AppIdea


def print_section(title: str, char: str = "=") -> None:
    print(f"\n{char * 60}")
    print(f"  {title}")
    print(f"{char * 60}")


def print_architecture(arch) -> None:
    print_section(f"🏗️  {arch.app_name}")
    print(f"\n{arch.summary}")
    print(f"\nEstimated Complexity: {arch.estimated_complexity.upper()}")

    if arch.notes:
        print(f"\n⚠️  Notes: {arch.notes}")

    print_section("📱 Apps & Services", "-")
    for app in arch.apps:
        print(f"\n  [{app.type.upper()}] {app.name}")
        print(f"  {app.description}")
        print(f"  Technologies: {', '.join(app.technologies)}")

    print_section("🤖 AI Models", "-")
    for model in arch.ai_models:
        print(f"\n  {model.name}")
        print(f"  Purpose: {model.purpose}")
        print(f"  Suggested: {model.suggested_model}")
        if model.notes:
            print(f"  Notes: {model.notes}")

    print_section("🧠 Agents", "-")
    for agent in arch.agents:
        print(f"\n  {agent.name}")
        print(f"  Role: {agent.role}")
        print(f"  Skills: {', '.join(agent.skills)}")
        print(f"  Tools: {', '.join(agent.tools)}")

    print_section("⚡ Skills", "-")
    for skill in arch.skills:
        print(f"\n  {skill.name}")
        print(f"  {skill.description}")
        print(f"  Used by: {', '.join(skill.used_by)}")

    print_section("🗄️  Databases", "-")
    for db in arch.databases:
        print(f"\n  [{db.type.upper()}] {db.suggested_technology}")
        print(f"  Entities: {', '.join(db.main_entities)}")
        if db.notes:
            print(f"  Notes: {db.notes}")

    print_section("☁️  Infrastructure", "-")
    for infra in arch.infrastructure:
        print(f"\n  {infra.name}")
        print(f"  Purpose: {infra.purpose}")
        print(f"  Suggested: {infra.suggested_service}")

    print_section("📋 Implementation Steps", "-")
    for step in arch.implementation_steps:
        print(f"\n  Step {step.step_number}: {step.title}")
        print(f"  {step.description}")
        if step.deliverables:
            print("  Deliverables:")
            for d in step.deliverables:
                print(f"    • {d}")

    print("\n" + "=" * 60)


def main():
    print("=" * 60)
    print("  🚀 App Idea Architecture Advisor")
    print("=" * 60)
    print("\nDescribe your app idea and I'll generate a full architecture plan.")
    print("(Press Ctrl+C to exit)\n")

    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set.")
        print("   Set it with: export OPENAI_API_KEY=your-key-here")
        sys.exit(1)

    description = input("What is your app idea?\n> ").strip()
    if not description:
        print("No description provided. Exiting.")
        sys.exit(1)

    target_users = input("\nWho are the target users? (press Enter to skip)\n> ").strip() or None

    features_input = input("\nList key features separated by commas (press Enter to skip)\n> ").strip()
    key_features = [f.strip() for f in features_input.split(",") if f.strip()] or None

    idea = AppIdea(
        description=description,
        target_users=target_users,
        key_features=key_features,
    )

    print("\n⏳ Generating architecture plan...")
    try:
        architecture = generate_architecture(idea)
        print_architecture(architecture)
    except EnvironmentError as exc:
        print(f"\n❌ Error: {exc}")
        sys.exit(1)
    except Exception as exc:
        print(f"\n❌ Unexpected error: {exc}")
        sys.exit(1)


if __name__ == "__main__":
    main()
