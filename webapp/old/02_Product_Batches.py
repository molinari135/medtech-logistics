import streamlit as st
import pandas as pd
import oracledb
import db_utils

st.title("📦 Product Batch Data")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to view this page. Please go to the **'Login'** page.")
else:
    st.write(f"Viewing data as: **`{db_utils.st.session_state.logged_in_user}`**")
    try:
        with db_utils.st.session_state.db_pool.acquire() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    '''
                    SELECT 
                        DEREF(BatchProduct).SerialNo AS SerialNo,
                        ROUND(SUM(Quantity)) AS TotalQuantity,
                        MIN(ArrivalDate) AS FirstArrival,
                        MAX(ArrivalDate) AS LastArrival,
                        COUNT(BatchID) AS BatchCount
                    FROM ProductBatch
                    GROUP BY DEREF(BatchProduct).SerialNo
                    '''
                )
                rows = cursor.fetchall()
                if rows:
                    columns = [desc[0] for desc in cursor.description]
                    df = pd.DataFrame(rows, columns=columns)
                    st.dataframe(df, use_container_width=True)
                    st.info(f"Showing {len(df)} rows from ProductBatch (Product REF DEREFed).")
                else:
                    st.info("ProductBatch table is empty or no data accessible.")
    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Database Error: {error_obj.message}")
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
