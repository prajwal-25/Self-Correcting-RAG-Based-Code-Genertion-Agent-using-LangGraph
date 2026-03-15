"""
FastAPI server wrapping the LangGraph code generation agent.

Start with:
    uvicorn api:app --reload --port 8000

Set MISTRAL_API_KEY in your environment (or a .env file) before starting.
"""

import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables (API keys) from .env
load_dotenv()

# ── Import agent (loads RAG index on first import) ──────────────────────────
from agent import run_agent


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------
class GenerateRequest(BaseModel):
    question: str
    thread_id: str | None = None  # pass to continue a conversation


class GenerateResponse(BaseModel):
    prefix: str
    imports: str
    code: str
    iterations: int
    error: str
    thread_id: str


# ---------------------------------------------------------------------------
# App lifecycle
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # agent module already initialises the index at import time
    print("Agent ready.")
    yield
    print("Shutting down.")


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Coder Agent API",
    description="Self-correcting RAG code-generation agent powered by Mistral + LangGraph.",
    version="1.0.0",
    lifespan=lifespan,
)

# Allow all origins so the Flutter web build (served from any port/domain)
# can reach the API without CORS errors.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/health", tags=["Utility"])
async def health():
    return {"status": "ok"}


@app.post("/generate", response_model=GenerateResponse, tags=["Agent"])
async def generate(req: GenerateRequest):
    """
    Generate a Python code solution for the given question.

    The agent:
    1. Retrieves relevant Python docs (RAG).
    2. Generates code via Mistral.
    3. Executes & checks the code; retries up to 3 times if it fails.
    """
    if not req.question.strip():
        raise HTTPException(status_code=422, detail="Question must not be empty.")

    try:
        result = run_agent(
            question=req.question,
            thread_id=req.thread_id or str(uuid.uuid4()),
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    return GenerateResponse(**result)


# ---------------------------------------------------------------------------
# Static Web Hosting (Production Deployment)
# ---------------------------------------------------------------------------
# Serve the compiled Flutter web app if it exists.
# This allows deploying both frontend and backend as a single service.
web_build_dir = os.path.join(os.path.dirname(__file__), "coder_app", "build", "web")

if os.path.exists(web_build_dir):
    app.mount("/", StaticFiles(directory=web_build_dir, html=True), name="static")

    # Fallback for Flutter deep linking (SPA routing)
    @app.exception_handler(404)
    async def custom_404_handler(request: Request, exc: Exception):
        index_path = os.path.join(web_build_dir, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return {"detail": "Not Found"}
