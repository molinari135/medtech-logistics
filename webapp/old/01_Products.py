import streamlit as st
import pandas as pd
import oracledb
import db_utils  # Import your database utility functions

st.title("📊 Product Data")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to view this page. Please go to the **'Login'** page.")
else:
    st.write(f"Viewing data as: **`{db_utils.st.session_state.logged_in_user}`**")
    try:
        with db_utils.st.session_state.db_pool.acquire() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    'SELECT * FROM Product'
                )
                rows = cursor.fetchall()
                if rows:
                    columns = [desc[0] for desc in cursor.description]
                    df = pd.DataFrame(rows, columns=columns)
                    st.dataframe(df, use_container_width=True)
                    st.info(f"Showing {len(df)} rows from Product.")
                else:
                    st.info("Product table is empty or no data accessible.")
    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Database Error: {error_obj.message}")
        st.warning("Ensure 'C##MEDTECHDBA' owns the 'PRODUCT' table and has SELECT privileges on it.")
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
