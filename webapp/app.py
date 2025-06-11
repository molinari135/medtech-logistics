# webapp/app.py
import streamlit as st
import db_utils # Import your database utility functions

# --- App Title and Introduction ---
st.set_page_config(layout="wide") # Use wide layout
st.title("📦 MedTech Supply Chain Management")
st.markdown("Welcome to the MedTech Supply Chain Database Viewer. Use the sidebar to navigate.")

st.subheader("Database Connection Manager")

# --- Display Connection Status ---
if db_utils.st.session_state.db_connected:
    st.success(f"🟢 Connected to Database as `{db_utils.DB_USER}`")
else:
    st.error("🔴 Disconnected from Database")

# --- Connect/Disconnect Buttons ---
col1, col2 = st.columns(2)

with col1:
    if st.button("Connect to DB"):
        db_utils.get_db_pool()
         # Rerun to update status and enable pages

with col2:
    if st.button("Disconnect from DB"):
        db_utils.close_db_pool()
         # Rerun to update status and disable pages

st.markdown("---")
st.write("To view database tables, connect above and select a page from the sidebar.")

# Optional: A simple query example if connected
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