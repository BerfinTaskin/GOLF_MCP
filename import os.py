import os
import sys

def run_report(sql_path: str):
    # Get the current file's directory (Smart_GMCP)
    current_file = os.path.abspath(__file__)
    project_root = os.path.dirname(current_file)  # /home/berfintskn/Smart_GMCP
    
    # Path to mcp_server/dist directory
    dist_dir = os.path.join(project_root, "mcp_server", "dist")
    
    # Full path to SQL file
    full_sql_path = os.path.join(dist_dir, sql_path)
    
    # Debug logging
    print(f"DEBUG: current_file={current_file}")
    print(f"DEBUG: project_root={project_root}")
    print(f"DEBUG: dist_dir={dist_dir}")
    print(f"DEBUG: sql_path={sql_path}")
    print(f"DEBUG: full_sql_path={full_sql_path}")
    print(f"DEBUG: SQL file exists: {os.path.exists(full_sql_path)}")
    
    # Check if the directories exist
    print(f"DEBUG: mcp_server exists: {os.path.exists(os.path.join(project_root, 'mcp_server'))}")
    print(f"DEBUG: dist exists: {os.path.exists(dist_dir)}")
    print(f"DEBUG: tum_sorgular exists: {os.path.exists(os.path.join(dist_dir, 'tum_sorgular'))}")
    
    return full_sql_path

if __name__ == "__main__":
    print("🔍 Testing SQL Path Resolution")
    result = run_report("tum_sorgular/Arşiv_Verileri-POSTGRESQL.sql")
    print(f"Final path: {result}")
    