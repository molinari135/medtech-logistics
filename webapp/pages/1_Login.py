# webapp/pages/Login.py
import streamlit as st
import db_utils # Import your database utility functions

st.title("🔐 Login to Oracle Database")
st.markdown("Select your username and enter your password to connect to the database.")

# Fetch user list only once or when needed
if 'db_users_list' not in st.session_state:
    st.session_state.db_users_list = db_utils.get_all_db_users()

# --- Login Form ---
with st.form("login_form"):
    selected_user = st.selectbox(
        "Select Username:",
        options=st.session_state.db_users_list
    )
    password = st.text_input("Password:", type="password")

    submit_button = st.form_submit_button("Login")

    if submit_button:
        # Attempt to initialize the database pool with provided credentials
        success = db_utils.initialize_db_pool(selected_user, password)
        if success:
            st.success("Login successful! You can now navigate to other pages.")
            st.rerun() # Rerun to update sidebar and state

# Health Check for DB Connection
if db_utils.st.session_state.db_connected and db_utils.st.session_state.db_pool:
    st.subheader("Quick Test Query")
    if st.button("Get DB SYSDATE"):
        try:
            with db_utils.st.session_state.db_pool.acquire() as connection:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT SYSDATE FROM DUAL")
                    db_time = cursor.fetchone()[0]
                    st.success(f"Current DB SYSDATE: {db_time.strftime('%Y-%m-%d %H:%M:%S')}")
        except Exception as e:
            st.error(f"Error performing test query: {e}")

# --- Logout Button ---
if db_utils.st.session_state.logged_in_user:
    st.markdown("---")
    st.write(f"Logged in as: **`{db_utils.st.session_state.logged_in_user}`**")
    if st.button("Logout"):
        db_utils.logout()
        st.rerun() # Rerun to go back to logged out state and potentially login page
