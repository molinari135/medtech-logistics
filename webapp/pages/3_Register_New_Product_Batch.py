import streamlit as st
import oracledb
import db_utils
from datetime import date

st.title("📦 Register a New Product Batch")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to register a new product batch. Please go to the **'Login'** page.")
else:
    with db_utils.st.session_state.db_pool.acquire() as connection:
        # Fetch available products
        with connection.cursor() as cursor:
            cursor.execute("SELECT SerialNo, ProductCategory, ExpiryDate FROM Product ORDER BY SerialNo")
            products = cursor.fetchall()
        # Fetch distribution centers and their stocked products
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT dc.CenterName, DEREF(p.COLUMN_VALUE).SerialNo
                FROM DistributionCenter dc, TABLE(dc.ListOfProducts) p
            """)
            dc_products = cursor.fetchall()
            # Build: {SerialNo: [CenterName, ...]}
            product_to_centers = {}
            for center, serial in dc_products:
                product_to_centers.setdefault(serial, []).append(center)
        # Get next BatchID
        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(BatchID), 0) + 1 FROM ProductBatch")
            next_batch_id = cursor.fetchone()[0]

        with st.form("register_batch_form"):
            st.subheader("Register a New Product Batch")
            st.info(f"Next Batch ID will be: {next_batch_id}")
            product_options = {f"SerialNo: {row[0]} | Category: {row[1]} | Expiry: {row[2].strftime('%Y-%m-%d') if row[2] else 'N/A'}": row[0] for row in products}
            product_label = st.selectbox(
                "Select Product",
                list(product_options.keys()),
                key="product_select"
            )
            serial_no = product_options[product_label]
            # Only allow centers where the product is present in the list of
            # available products
            allowed_centers = product_to_centers.get(serial_no, [])
            # Use st.empty() to refresh the hint when the product changes
            hint_container = st.empty()
            if allowed_centers:
                hint_container.info(
                    "Distribution centers providing this product: "
                    + ", ".join(allowed_centers)
                )
            if not allowed_centers:
                hint_container.error(
                    "No distribution center has this product in its list of "
                    "available products."
                )
                center = None
            else:
                center = st.selectbox(
                    "Select Distribution Center (where product is available)",
                    allowed_centers
                )
            quantity = st.number_input("Quantity", min_value=1, step=1)
            arrival_date = st.date_input("Arrival Date", value=date.today())
            submitted = st.form_submit_button("Register Batch")
        if submitted and center:
            try:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        INSERT INTO ProductBatch \
                        (BatchID, BatchProduct, Quantity, ArrivalDate)
                        VALUES (
                            :batch_id,
                            (SELECT REF(p) FROM Product p \
                             WHERE p.SerialNo = :serial_no),
                            :quantity,
                            :arrival_date
                        )
                        """,
                        {
                            'batch_id': int(next_batch_id),
                            'serial_no': serial_no,
                            'quantity': int(quantity),
                            'arrival_date': arrival_date
                        }
                    )
                    connection.commit()
                    st.success(
                        f"Batch {next_batch_id} registered for product "
                        f"{serial_no}."
                    )
            except oracledb.Error as e:
                error_obj, = e.args
                st.error(f"Database Error: {error_obj.message}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")