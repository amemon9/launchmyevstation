import os
import dotenv
from . import tools
from google.adk.agents import LlmAgent

dotenv.load_dotenv()

# Force the ADK to use Vertex AI instead of the Gemini Developer API
os.environ['GOOGLE_GENAI_USE_VERTEXAI'] = 'true'
os.environ['GOOGLE_CLOUD_LOCATION'] = 'global'

PROJECT_ID = os.getenv('GOOGLE_CLOUD_PROJECT', 'project_not_set')

def get_agent():
    maps_toolset = tools.get_maps_mcp_toolset()
    bigquery_toolset = tools.get_bigquery_mcp_toolset()

    return LlmAgent(
        model='gemini-3.1-pro-preview',
        name='root_agent',
        instruction=f"""
                    Help the user answer questions by strategically combining insights from two sources:
                    
                    1.  **BigQuery toolset:** Access demographic (inc. foot traffic index), product pricing, and historical sales data in the  mcp_evstation dataset. Do not use any other dataset.
                    Run all query jobs from project id: {PROJECT_ID}. 

                    2.  **Maps Toolset:** Use this for real-world location analysis, finding competition/places and calculating necessary travel routes.
                        Include a hyperlink to an interactive map in your response where appropriate.
                """,
        tools=[maps_toolset, bigquery_toolset]
    )

root_agent = get_agent()
