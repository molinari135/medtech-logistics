import streamlit as st
import oracledb
import db_utils
from datetime import date

st.title("⏰ List All Batches of Expired Products")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to view expired product batches. Please go to the **'Login'** page.")
else:
    with db_utils.st.session_state.db_pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT pb.BatchID, DEREF(pb.BatchProduct).SerialNo, 
                       DEREF(pb.BatchProduct).ProductCategory, 
                       DEREF(pb.BatchProduct).ExpiryDate, pb.Quantity, 
                       pb.ArrivalDate, DEREF(pb.ByDistCenter).CenterName
                FROM ProductBatch pb
                WHERE DEREF(pb.BatchProduct).ExpiryDate < TRUNC(SYSDATE)
                ORDER BY pb.BatchID
                '''
            )
            rows = cursor.fetchall()
        if not rows:
            st.info("No expired product batches found.")
        else:
            st.dataframe(
                [
                    {
                        "BatchID": row[0],
                        "Product SerialNo": row[1],
                        "Category": row[2],
                        "Expiry Date": row[3].strftime('%Y-%m-%d') if row[3] else '',
                        "Quantity": row[4],
                        "Arrival Date": row[5].strftime('%Y-%m-%d'),
                        "Distribution Center": row[6]
                    }
                    for row in rows
                ],
                use_container_width=True
            )
