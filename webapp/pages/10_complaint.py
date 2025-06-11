import streamlit as st
import pandas as pd
import oracledb
import db_utils

st.title("📝 Complaint Data")

if not db_utils.st.session_state.db_connected:
    st.warning("Please connect to the database on the Home page first.")
else:
    if st.button("Load Complaint Data"):
        try:
            with db_utils.st.session_state.db_pool.acquire() as connection:
                with connection.cursor() as cursor:
                    cursor.execute(
                        'SELECT * FROM ViewComplaintDetails'
                    )
                    rows = cursor.fetchall()
                    if rows:
                        columns = [desc[0] for desc in cursor.description]
                        df = pd.DataFrame(rows, columns=columns)
                        st.dataframe(df, use_container_width=True)
                        st.info(f"Showing {len(df)} rows from Complaint.")
                    else:
                        st.info("Complaint table is empty or no data accessible.")
        except oracledb.Error as e:
            error_obj, = e.args
            st.error(f"Database Error: {error_obj.message}")
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")