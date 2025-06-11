import streamlit as st
import oracledb
import db_utils
from datetime import date

st.title("🚚 Assign Delivery to Logistics Team")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to assign a delivery. Please go to the **'Login'** page.")
else:
    with db_utils.st.session_state.db_pool.acquire() as connection:
        # Fetch all batch orders that are not yet delivered or cancelled
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT bo.OrderID, bo.DeliveryStatus, DEREF(bo.ByLogisticTeam).TeamCode, DEREF(bo.ByLogisticTeam).TeamName
                FROM BatchOrder bo
                WHERE bo.DeliveryStatus NOT IN ('Delivered', 'Cancelled')
                ORDER BY bo.OrderID
                """
            )
            orders = cursor.fetchall()
        # Build order options
        order_options = {
            f"OrderID: {row[0]} | Status: {row[1]} | Current Team: {row[3]} (Code: {row[2]})": row[0]
            for row in orders
        }
        with st.form("assign_delivery_form"):
            st.subheader("Assign a Delivery to a Logistics Team")
            if not order_options:
                st.info("No active orders available for assignment.")
                st.stop()
            order_label = st.selectbox("Select Order to Assign", list(order_options.keys()))
            order_id = order_options[order_label]

            # Get the first batch of the selected order
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT DEREF(CAST(COLUMN_VALUE AS REF ProdBatch_t)).BatchID
                    FROM TABLE(
                        SELECT OrderBatches FROM BatchOrder WHERE OrderID = :order_id
                    )
                    WHERE ROWNUM = 1
                    """,
                    {'order_id': order_id}
                )
                batch_row = cursor.fetchone()
                if not batch_row:
                    st.warning("Selected order has no batches.")
                    st.stop()
                first_batch_id = batch_row[0]

                # Find the distribution center of the batch
                cursor.execute(
                    """
                    SELECT DEREF(ByDistCenter).CenterName
                    FROM ProductBatch
                    WHERE BatchID = :batch_id
                    """,
                    {'batch_id': first_batch_id}
                )
                dc_row = cursor.fetchone()
                if not dc_row:
                    st.warning("Distribution center not found for the batch.")
                    st.stop()
                center_name = dc_row[0]

                # Find teams related to that center
                cursor.execute(
                    """
                    SELECT dc.ByTeam.TeamCode, lt.TeamName
                    FROM DistributionCenter dc
                    JOIN LogisticTeam lt ON lt.TeamCode = dc.ByTeam.TeamCode
                    WHERE dc.CenterName = :center_name
                    """,
                    {'center_name': center_name}
                )
                teams = cursor.fetchall()
                if not teams:
                    st.warning("No teams found for the distribution center.")
                    st.stop()
                team_options = {f"{row[1]} (Code: {row[0]})": row[0] for row in teams}

            st.info(f"Distribution Center for first batch: **{center_name}**")
            team_label = st.selectbox("Select Logistics Team", list(team_options.keys()))
            team_code = team_options[team_label]
            submitted = st.form_submit_button("Assign Team")
        if submitted:
            try:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        UPDATE BatchOrder
                        SET ByLogisticTeam = (SELECT REF(t) FROM LogisticTeam t WHERE t.TeamCode = :team_code)
                        WHERE OrderID = :order_id
                        """,
                        {'team_code': team_code, 'order_id': order_id}
                    )
                    connection.commit()
                    st.success(f"Order {order_id} assigned to team {team_label}.")
            except oracledb.Error as e:
                error_obj, = e.args
                st.error(f"Database Error: {error_obj.message}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")
