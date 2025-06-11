import streamlit as st
import pandas as pd
import oracledb
import db_utils

st.title("🛒 Batch Order Data")
st.subheader("Including Flattened Order Batches")

if not db_utils.st.session_state.db_connected:
    st.warning("Please connect to the database on the Home page first.")
else:
    if st.button("Load Batch Order Data"):
        try:
            with db_utils.st.session_state.db_pool.acquire() as connection:
                with connection.cursor() as cursor:
                    # Query the flattened view for Batch Orders with OrderBatches
                    cursor.execute(
                        'SELECT * FROM ViewBatchOrderDetails'
                    )
                    rows = cursor.fetchall()
                    if rows:
                        columns = [desc[0] for desc in cursor.description]
                        df = pd.DataFrame(rows, columns=columns)
                        st.dataframe(df, use_container_width=True)
                        st.info(f"Showing {len(df)} rows from ViewBatchOrderDetails.")
                    else:
                        st.info("ViewBatchOrderDetails view is empty or no data accessible.")
        except oracledb.Error as e:
            error_obj, = e.args
            st.error(f"Database Error: {error_obj.message}")
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")