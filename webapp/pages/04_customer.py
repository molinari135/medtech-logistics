import streamlit as st
import pandas as pd
import oracledb
import db_utils

st.title("👤 Customer Data")
st.subheader("Including Flattened Department Affiliations")

if not db_utils.st.session_state.db_connected:
    st.warning("Please connect to the database on the Home page first.")
else:
    if st.button("Load Customer Data"):
        try:
            with db_utils.st.session_state.db_pool.acquire() as connection:
                with connection.cursor() as cursor:
                    # Query the flattened view for Customers with BelongsToDepts
                    cursor.execute(
                        '''
                        SELECT
                            CustomerCode,
                            CustomerCity,
                            CustomerStreet,
                            CustomerStreetNo,
                            CustomerZipCode,
                            LISTAGG(DepartmentID, ', ') WITHIN GROUP (ORDER BY DepartmentID) AS DepartmentIDs,
                            LISTAGG(DepartmentEmail, ', ') WITHIN GROUP (ORDER BY DepartmentID) AS DepartmentEmails,
                            LISTAGG(DepartmentFax, ', ') WITHIN GROUP (ORDER BY DepartmentID) AS DepartmentFaxes
                        FROM ViewCustomerDeptAffiliation
                        GROUP BY
                            CustomerCode,
                            CustomerCity,
                            CustomerStreet,
                            CustomerStreetNo,
                            CustomerZipCode
                        '''
                    )
                    rows = cursor.fetchall()
                    if rows:
                        columns = [desc[0] for desc in cursor.description]
                        df = pd.DataFrame(rows, columns=columns)
                        st.dataframe(df, use_container_width=True)
                        st.info(f"Showing {len(df)} rows from ViewCustomerDeptAffiliation.")
                    else:
                        st.info("ViewCustomerDeptAffiliation view is empty or no data accessible.")
        except oracledb.Error as e:
            error_obj, = e.args
            st.error(f"Database Error: {error_obj.message}")
        except Exception as e:
            st.error(f"An unexpected error occurred: {e}")