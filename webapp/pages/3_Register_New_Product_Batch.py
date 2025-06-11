import streamlit as st
import oracledb
import db_utils
from datetime import date

st.title("📦 Register a New Product Batch")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to register a new product batch. Please go to the **'Login'** page.")
else:
    with db_utils.st.session_state.db_pool.acquire() as connection:
        # Fetch distribution centers
        with connection.cursor() as cursor:
            cursor.execute("SELECT CenterName FROM DistributionCenter ORDER BY CenterName")
            centers = [row[0] for row in cursor.fetchall()]

        # Get next BatchID (move this before center selection)
        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(BatchID), 0) + 1 FROM ProductBatch")
            next_batch_id = cursor.fetchone()[0]

        # Select center outside the form so product list updates on change
        center = st.selectbox(
            "Select Distribution Center", centers, key="center_select"
        )

        # Fetch products available at the selected center
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT DEREF(p.COLUMN_VALUE).SerialNo, DEREF(p.COLUMN_VALUE).ProductCategory, 
                       DEREF(p.COLUMN_VALUE).ExpiryDate
                FROM DistributionCenter dc, TABLE(dc.ListOfProducts) p
                WHERE dc.CenterName = :center
                ORDER BY DEREF(p.COLUMN_VALUE).SerialNo
                ''',
                {'center': center}
            )
            center_products = cursor.fetchall()

        if not center_products:
            st.warning("No products available at this distribution center.")
            st.stop()

        product_options = {
            f"SerialNo: {row[0]} | Category: {row[1]} | Expiry: {row[2].strftime('%Y-%m-%d') if row[2] else 'N/A'}": row[0]
            for row in center_products
        }

        with st.form("register_batch_form"):
            st.subheader("Register a New Product Batch")
            st.info(f"Next Batch ID will be: {next_batch_id}")
            product_label = st.selectbox(
                "Select Product (available at this center)",
                list(product_options.keys()),
                key="product_select"
            )
            serial_no = product_options[product_label]
            quantity = st.number_input("Quantity", min_value=1, step=1)
            arrival_date = st.date_input("Arrival Date", value=date.today())
            submitted = st.form_submit_button("Register Batch")
        if submitted:
            try:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        INSERT INTO ProductBatch \
                        (BatchID, BatchProduct, Quantity, ArrivalDate, ByDistCenter)
                        VALUES (
                            :batch_id,
                            (SELECT REF(p) FROM Product p \
                             WHERE p.SerialNo = :serial_no),
                            :quantity,
                            :arrival_date,
                            (SELECT REF(dc) FROM DistributionCenter dc \
                             WHERE dc.CenterName = :center)
                        )
                        """,
                        {
                            'batch_id': int(next_batch_id),
                            'serial_no': serial_no,
                            'quantity': int(quantity),
                            'arrival_date': arrival_date,
                            'center': center
                        }
                    )
                    connection.commit()
                    st.success(
                        f"Batch {next_batch_id} registered for product "
                        f"{serial_no} at {center}."
                    )
            except oracledb.Error as e:
                error_obj, = e.args
                st.error(f"Database Error: {error_obj.message}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")