import os
import io
import contextlib
import uuid
from typing import Annotated, TypedDict, Literal

from pydantic import BaseModel, Field
from langchain_mistralai import ChatMistralAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langgraph.graph import END, StateGraph, START
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph.message import AnyMessage, add_messages

# ---------------------------------------------------------------------------
# 1. Configuration & LLM Setup
# ---------------------------------------------------------------------------
MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY")
if not MISTRAL_API_KEY:
    raise RuntimeError("Please set MISTRAL_API_KEY in your environment.")

llm = ChatMistralAI(model="mistral-large-latest", temperature=0)

# ---------------------------------------------------------------------------
# 2. Structured Output Schema
# ---------------------------------------------------------------------------
class CodeSchema(BaseModel):
    """Schema for code solutions."""
    prefix: str = Field(description="Description of the problem and approach")
    imports: str = Field(description="Code block import statements")
    code: str = Field(description="The functional code block")

code_gen_chain = llm.with_structured_output(CodeSchema)

# ---------------------------------------------------------------------------
# 3. RAG Setup  (loaded once at module import)
# ---------------------------------------------------------------------------
_URLS = [
    "https://docs.python.org/3/tutorial/introduction.html",
    "https://docs.python.org/3/tutorial/controlflow.html",
]

def _build_retriever():
    loader = WebBaseLoader(_URLS)
    docs = loader.load()
    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
    splits = splitter.split_documents(docs)
    embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
    vectorstore = FAISS.from_documents(splits, embeddings)
    return vectorstore.as_retriever(search_kwargs={"k": 3})

retriever = _build_retriever()

# ---------------------------------------------------------------------------
# 4. Graph State
# ---------------------------------------------------------------------------
class GraphState(TypedDict):
    error: str
    messages: Annotated[list[AnyMessage], add_messages]
    generation: CodeSchema
    iterations: int
    retrieved_docs: str

# ---------------------------------------------------------------------------
# 5. Node Functions
# ---------------------------------------------------------------------------
def retrieve(state: GraphState):
    question = state["messages"][-1].content
    docs = retriever.invoke(question)
    context = "\n\n".join(doc.page_content for doc in docs)
    return {"retrieved_docs": context}

def generate(state: GraphState):
    question = state["messages"][-1].content
    context = state["retrieved_docs"]
    error = state.get("error", "")

    system_prompt = (
        "You are an expert coding assistant. Use the context below to answer:\n"
        f"Context:\n{context}\n"
        f"Previous Error (if any): {error}\n"
        "Produce complete, runnable Python code."
    )

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("user", "{question}"),
    ])
    chain = prompt | code_gen_chain
    response = chain.invoke({"question": question})
    return {"generation": response, "iterations": state.get("iterations", 0) + 1}

def code_check(state: GraphState):
    code_solution = state["generation"]
    full_code = f"{code_solution.imports}\n{code_solution.code}"
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            exec(full_code, {})  # isolated namespace
        return {"error": "none"}
    except Exception as exc:
        return {"error": str(exc)}

def decide_to_finish(state: GraphState) -> Literal["end", "generate"]:
    if state["error"] == "none" or state.get("iterations", 0) >= 3:
        return "end"
    return "generate"

# ---------------------------------------------------------------------------
# 6. Graph Construction
# ---------------------------------------------------------------------------
def build_graph():
    builder = StateGraph(GraphState)
    builder.add_node("retrieve", retrieve)
    builder.add_node("generate", generate)
    builder.add_node("check_code", code_check)
    builder.add_edge(START, "retrieve")
    builder.add_edge("retrieve", "generate")
    builder.add_edge("generate", "check_code")
    builder.add_conditional_edges(
        "check_code",
        decide_to_finish,
        {"end": END, "generate": "generate"},
    )
    return builder.compile(checkpointer=InMemorySaver())

graph = build_graph()

# ---------------------------------------------------------------------------
# 7. Public API
# ---------------------------------------------------------------------------
def run_agent(question: str, thread_id: str | None = None) -> dict:
    """
    Run the code-generation agent for a given question.

    Args:
        question:  The natural-language coding question.
        thread_id: Optional conversation thread ID (UUID string).
                   Pass the same ID to continue a conversation.

    Returns:
        A dict with keys: prefix, imports, code, iterations, error, thread_id
    """
    tid = thread_id or str(uuid.uuid4())
    config = {"configurable": {"thread_id": tid}}
    final_state = None
    for event in graph.stream(
        {"messages": [("user", question)], "iterations": 0},
        config,
        stream_mode="values",
    ):
        final_state = event

    if final_state is None or "generation" not in final_state:
        return {
            "prefix": "",
            "imports": "",
            "code": "",
            "iterations": 0,
            "error": "No generation produced.",
            "thread_id": tid,
        }

    gen: CodeSchema = final_state["generation"]
    return {
        "prefix": gen.prefix,
        "imports": gen.imports,
        "code": gen.code,
        "iterations": final_state.get("iterations", 0),
        "error": final_state.get("error", "none"),
        "thread_id": tid,
    }