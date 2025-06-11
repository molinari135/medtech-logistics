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
# webapp/db_utils.py
import streamlit as st
import oracledb
import os

# --- Database Connection Details (Fixed for initial connection and fetching user list) ---
# When fetching the user list, we'll connect as SYSTEM as it has privileges on ALL_USERS.
# This password is the ORACLE_PWD from your docker-compose.yml.
SYS_DB_USER = "SYSTEM"
SYS_DB_PASSWORD = "password123"
DB_HOST = "localhost"
DB_PORT = "1521"
DB_SERVICE_NAME = "XE"

# --- Initialize session state variables ---
if 'db_pool' not in st.session_state:
    st.session_state.db_pool = None
if 'db_connected' not in st.session_state:
    st.session_state.db_connected = False
if 'logged_in_user' not in st.session_state:
    st.session_state.logged_in_user = None # New: Stores the username that successfully logged in

def get_all_db_users():
    """
    Connects as SYSTEM to fetch a list of all database users (excluding common system users).
    This is for demonstration purposes in the login dropdown.
    """
    users = []
    try:
        # Use a temporary connection for this privileged query
        with oracledb.connect(
            user=SYS_DB_USER,
            password=SYS_DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            service_name=DB_SERVICE_NAME
        ) as temp_conn:
            with temp_conn.cursor() as cursor:
                # Query ALL_USERS, excluding common Oracle system users
                cursor.execute("""
                    SELECT USERNAME FROM ALL_USERS
                    WHERE USERNAME = 'SYSTEM'
                       OR USERNAME LIKE 'C##%'
                    ORDER BY USERNAME
                """)
                for row in cursor:
                    users.append(row[0])
    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Error fetching DB users: {error_obj.message}")
        print(f"Error fetching DB users: {error_obj.message}")
    except Exception as e:
        st.error(f"An unexpected error occurred while fetching DB users: {e}")
        print(f"Unexpected error fetching DB users: {e}")
    return users


def initialize_db_pool(username, password):
    """
    Initializes and returns the Oracle DB connection pool using provided credentials.
    Stores the pool and connected status in session state.
    """
    if st.session_state.db_pool: # Close any existing pool first
        try:
            st.session_state.db_pool.close()
            st.session_state.db_pool = None
        except Exception as e:
            print(f"Warning: Error closing existing DB pool during re-initialization: {e}")

    print(f"Attempting to initialize database connection pool for user: {username}...")
    try:
        pool = oracledb.create_pool(
            user=username,
            password=password,
            host=DB_HOST,
            port=DB_PORT,
            service_name=DB_SERVICE_NAME,
            min=1, # Min connections for login
            max=3, # Max connections for login
            increment=1,
        )
        st.session_state.db_pool = pool
        st.session_state.db_connected = True
        st.session_state.logged_in_user = username
        st.success(f"Successfully connected to the database as `{username}`!")
        print(f"Database connection pool initialized successfully for {username}.")
        return True # Indicate success
    except oracledb.Error as e:
        error_obj, = e.args
        st.session_state.db_connected = False
        st.session_state.logged_in_user = None
        st.error(f"Failed to connect to database: {error_obj.message}")
        print(f"Error initializing DB pool for {username}: {error_obj.message}")
        return False # Indicate failure
    except Exception as e:
        st.session_state.db_connected = False
        st.session_state.logged_in_user = None
        st.error(f"An unexpected error occurred during connection: {e}")
        print(f"Unexpected error during connection: {e}")
        return False # Indicate failure

def logout():
    """Logs out the user and closes the database pool."""
    close_db_pool() # Close the DB pool if it exists
    st.session_state.logged_in_user = None
    st.info("You have been logged out.")
    st.rerun() # Force rerun to clear state and show login page
    

def close_db_pool():
    """Closes the current database connection pool if it exists."""
    if st.session_state.db_pool:
        try:
            st.session_state.db_pool.close()
            st.session_state.db_pool = None
            st.session_state.db_connected = False
            print("Database connection pool closed.")
        except Exception as e:
            print(f"Error closing DB pool: {e}")
