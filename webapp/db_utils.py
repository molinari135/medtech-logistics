# webapp/db_utils.py
import streamlit as st
import oracledb
import os

# --- Database Connection Details ---
# These details are used by all pages to connect to the DB
DB_USER = "C##MEDTECHDBA" # Your schema owner user
DB_PASSWORD = "medtechdba" # Your schema owner's password
DB_HOST = "localhost"
DB_PORT = "1521"
DB_SERVICE_NAME = "XE"

# --- Functions to manage connection pool in st.session_state ---

def get_db_pool():
    """Initializes and returns the Oracle DB connection pool, stored in session state."""
    if 'db_pool' not in st.session_state or st.session_state.db_pool is None:
        print("Attempting to initialize database connection pool...")
        try:
            pool = oracledb.create_pool(
                user=DB_USER,
                password=DB_PASSWORD,
                host=DB_HOST,
                port=DB_PORT,
                service_name=DB_SERVICE_NAME,
                min=2,
                max=5,
                increment=1,
            )
            st.session_state.db_pool = pool
            st.session_state.db_connected = True
            st.success(f"Successfully connected to the database as {DB_USER}!")
            print("Database connection pool initialized successfully.")
        except oracledb.Error as e:
            error_obj, = e.args
            st.session_state.db_connected = False
            st.error(f"Failed to connect to database: {error_obj.message}")
            print(f"Error initializing DB pool: {error_obj.message}")
            st.stop() # Stop the app if connection fails critically
        except Exception as e:
            st.session_state.db_connected = False
            st.error(f"An unexpected error occurred during connection: {e}")
            print(f"Unexpected error: {e}")
            st.stop() # Stop the app if connection fails critically
    return st.session_state.db_pool

def close_db_pool():
    """Closes the Oracle DB connection pool and updates session state."""
    if 'db_pool' in st.session_state and st.session_state.db_pool:
        try:
            st.session_state.db_pool.close()
            st.session_state.db_pool = None
            st.session_state.db_connected = False
            st.warning("Database connection pool disconnected.")
            print("Database connection pool closed.")
        except Exception as e:
            st.error(f"Error closing database pool: {e}")
            print(f"Error closing DB pool: {e}")
    else:
        st.info("No database pool to disconnect.")
        st.session_state.db_connected = False

# --- Initialize session state variables if they don't exist ---
if 'db_connected' not in st.session_state:
    st.session_state.db_connected = False
if 'db_pool' not in st.session_state: # This might get initialized by get_db_pool() directly
    st.session_state.db_pool = None