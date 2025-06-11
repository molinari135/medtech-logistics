# webapp/app.py
import streamlit as st
import db_utils # Import your database utility functions


st.title("📦 MedTech Supply Chain Management")
st.markdown("Welcome to the MedTech Supply Chain Database Viewer.")

if db_utils.st.session_state.logged_in_user:
    st.success(f"You are logged in as: **`{db_utils.st.session_state.logged_in_user}`**")
    st.markdown("Use the sidebar to navigate to view table data.")
else:
    st.warning("Please navigate to the **'Login'** page in the sidebar to connect to the database.")

st.markdown("---")

# Optional: Display a small status on the home page
if db_utils.st.session_state.db_connected:
    st.info("Database connection pool is active.")
else:
    st.info("Database connection pool is inactive.")
