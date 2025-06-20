import streamlit as st
import oracledb
import db_utils
from datetime import date

st.title("📋 View Deliveries Assigned to a Team")

if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to view deliveries. Please go to the **'Login'** page.")
else:
    with db_utils.st.session_state.db_pool.acquire() as connection:
        # Fetch all chief officers
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT c.TaxCode, c.MemberName, c.MemberSurname
                FROM ChiefOfficier c
                WHERE EXISTS (
                    SELECT 1 FROM LogisticTeam t WHERE t.TeamChief = REF(c)
                )
                ORDER BY c.MemberSurname, c.MemberName
                """
            )
            chiefs = cursor.fetchall()
        chief_options = {
            f"{(row[1] or '')} {(row[2] or '')} (TaxCode: {row[0]})": row[0]
            for row in sorted(chiefs, key=lambda r: r[0])
        }
        with st.form("select_chief_form"):
            st.subheader("Select Chief Officer to View Team Deliveries")
            if not chief_options:
                st.info("No chief officers found.")
                st.stop()
            chief_label = st.selectbox(
                "Chief Officer",
                list(chief_options.keys())
            )
            chief_taxcode = chief_options[chief_label]
            submitted = st.form_submit_button("View Deliveries")
        if submitted:
            # Find the team(s) coordinated by this chief
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT TeamCode, TeamName FROM LogisticTeam "
                    "WHERE TeamChief = (SELECT REF(c) FROM ChiefOfficier c "
                    "WHERE c.TaxCode = :taxcode)",
                    {'taxcode': chief_taxcode}
                )
                teams = cursor.fetchall()
            if not teams:
                st.info("No teams found for this chief officer.")
                st.stop()
            team_codes = [row[0] for row in teams]
            team_names = [row[1] for row in teams]
            # Show the taxcodes of the chiefs for the selected teams
            format_codes = ','.join(str(tc) for tc in team_codes)
            with connection.cursor() as cursor:
                cursor.execute(
                    f'''
                    SELECT DISTINCT DEREF(lt.TeamChief).TaxCode
                    FROM LogisticTeam lt
                    WHERE lt.TeamCode IN ({format_codes})
                    '''
                )
                chief_taxcodes = [row[0] for row in cursor.fetchall()]
            st.markdown(
                f"**Chief TaxCodes for selected teams:** "
                f"{', '.join(str(tc) for tc in chief_taxcodes)}"
            )
            st.markdown(f"### Deliveries for Team(s): {', '.join(team_names)}")
            # Fetch all deliveries (orders) assigned to these teams
            with connection.cursor() as cursor:
                cursor.execute(
                    f'''
                    SELECT bo.OrderID, bo.OrderDate, bo.ExpectedDeliveryDate,
                           bo.DeliveryStatus, DEREF(bo.ByCustomer).CustomerCode
                    FROM BatchOrder bo
                    WHERE DEREF(bo.ByLogisticTeam).TeamCode IN ({format_codes})
                    ORDER BY bo.OrderID
                    '''
                )
                deliveries = cursor.fetchall()
            if not deliveries:
                st.info("No deliveries assigned to this team.")
            else:
                st.dataframe(
                    [
                        {
                            "OrderID": row[0],
                            "Order Date": row[1].strftime('%Y-%m-%d'),
                            "Expected Delivery": row[2].strftime('%Y-%m-%d'),
                            "Status": row[3],
                            "Customer": row[4]
                        }
                        for row in deliveries
                    ],
                    use_container_width=True
                )
