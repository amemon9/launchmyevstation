import os
import traceback
import uvicorn
import uuid
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from mcp_evstation_app.agent import get_agent

app = FastAPI(title="Green Infrastructure Planner API")

session_service = InMemorySessionService()

class QueryRequest(BaseModel):
    prompt: str

@app.get("/")
def read_root():
    return {"message": "Welcome to the Green Infrastructure Planner API! Send a POST request to /plan to get started."}

@app.post("/plan")
async def plan_evstations(request: QueryRequest):
    try:
        session_id = str(uuid.uuid4())
        await session_service.create_session(
            app_name="evstation_app", user_id="api_user", session_id=session_id
        )
        
        content = types.Content(role="user", parts=[types.Part.from_text(text=request.prompt)])
        final_response = "No response generated."
        
        agent = get_agent()
        runner = Runner(agent=agent, app_name="evstation_app", session_service=session_service)

        async for event in runner.run_async(user_id="api_user", session_id=session_id, new_message=content):
            if event.is_final_response():
                final_response = event.content.parts[0].text
                
        return {"response": final_response}
    except Exception as e:
        print("Error during agent invocation:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Bind to $PORT for Cloud Run compliance
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
