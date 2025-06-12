import streamlit as st
import oracledb
import db_utils
from datetime import date, timedelta

st.title("🚚 Place New Batch Order")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to place a new order. Please go to the **'Login'** page.")
else:
    with db_utils.st.session_state.db_pool.acquire() as connection:
        # Fetch customers
        with connection.cursor() as cursor:
            cursor.execute("SELECT CustomerCode FROM Customer ORDER BY CustomerCode")
            customers = [row[0] for row in cursor.fetchall()]
        # Fetch product batches
        with connection.cursor() as cursor:
            cursor.execute("SELECT BatchID, DEREF(BatchProduct).SerialNo, Quantity, ArrivalDate FROM ProductBatch ORDER BY BatchID")
            batches = cursor.fetchall()
        # Fetch distribution centers and their products/teams
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT dc.CenterName, dc.ByTeam.TeamCode, lt.TeamName, 
                       DEREF(prod_list.COLUMN_VALUE).SerialNo AS StockedProductSerialNo
                FROM DistributionCenter dc
                JOIN LogisticTeam lt ON lt.TeamCode = dc.ByTeam.TeamCode
                , TABLE(dc.ListOfProducts) prod_list
            """)
            dc_rows = cursor.fetchall()
            # Build: {SerialNo: (CenterName, TeamCode, TeamName)}
            serial_to_dc = {}
            for row in dc_rows:
                center, team_code, team_name, serial_no = row
                serial_to_dc.setdefault(serial_no, []).append((center, team_code, team_name))
        # Get next OrderID
        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(OrderID), 0) + 1 FROM BatchOrder")
            next_order_id = cursor.fetchone()[0]

        # Map: center_name -> [batch rows]
        center_to_batches = {}
        for row in batches:
            # Find the center for this batch
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT dc.CenterName FROM DistributionCenter dc, "
                    "TABLE(dc.ListOfProducts) p WHERE DEREF(p.COLUMN_VALUE).SerialNo = :serial_no",
                    {'serial_no': row[1]}
                )
                center_name = cursor.fetchone()[0]
            center_to_batches.setdefault(center_name, []).append(row)
        # Let user select a center outside the form so batch list updates
        center = st.selectbox(
            "Select Distribution Center for this order",
            list(center_to_batches.keys()),
            key="order_center_select"
        )
        center_batches = center_to_batches[center]
        batch_label_map = {
            f"BatchID: {row[0]} | Product: {row[1]} | Qty: {row[2]} | Arrived: {row[3].strftime('%Y-%m-%d')}": row
            for row in center_batches
        }
        with st.form("quick_place_order_form"):
            st.subheader("Quick Place a New Batch Order")
            st.info(f"Next Order ID will be: {next_order_id}")
            customer = st.selectbox("Select Customer", customers)
            selected_batch_labels = st.multiselect(
                "Select Product Batches for Order (from this center only)",
                list(batch_label_map.keys())
            )
            selected_batches = [batch_label_map[lab] for lab in selected_batch_labels]
            expected_delivery = st.date_input(
                "Expected Delivery Date",
                value=date.today() + timedelta(days=2)
            )
            delivery_status = st.selectbox(
                "Delivery Status",
                [
                    "Pending", "In Transit", "Delivered",
                    "Cancelled", "Problem"
                ],
                index=0
            )
            submitted = st.form_submit_button("Place Order")
        if submitted:
            if not selected_batches:
                st.error(
                    "You must select at least one product batch."
                )
            else:
                try:
                    with connection.cursor() as cursor:
                        batch_ids = [str(b[0]) for b in selected_batches]
                        in_clause = ','.join(batch_ids)
                        cursor.execute(
                            f'''
                            INSERT INTO BatchOrder (
                                OrderID, OrderBatches, OrderDate,
                                ExpectedDeliveryDate, DeliveryStatus,
                                ByCustomer, ByLogisticTeam
                            )
                            VALUES (
                                :order_id,
                                (SELECT CAST(COLLECT(REF(pb)) AS BatchList)
                                 FROM ProductBatch pb
                                 WHERE pb.BatchID IN ({in_clause})
                                ),
                                :order_date,
                                :expected_delivery,
                                :status,
                                (SELECT REF(c) FROM Customer c
                                 WHERE c.CustomerCode = :customer),
                                NULL
                            )
                            ''',
                            {
                                'order_id': int(next_order_id),
                                'order_date': date.today(),
                                'expected_delivery': expected_delivery,
                                'status': delivery_status,
                                'customer': customer
                            }
                        )
                        connection.commit()
                        st.success(
                            f"Order {next_order_id} placed successfully."
                        )
                except oracledb.Error as e:
                    error_obj, = e.args
                    st.error(f"Database Error: {error_obj.message}")
                except Exception as e:
                    st.error(f"Unexpected error: {e}")
