# webapp/pages/Tables.py
import streamlit as st
import pandas as pd
import oracledb
import db_utils # Import your database utility functions

st.title("🗄️ MedTech Logistic Tables Overview")

def products():
    with st.expander("Products", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                'SELECT * FROM Product'
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from Product.")
            else:
                st.info("Product table is empty or no data accessible.")
        
                
def product_batches():
    with st.expander("Products Batches", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    PB.BatchID,
                    PB.Quantity,
                    PB.ArrivalDate,
                    DEREF(PB.BatchProduct).SerialNo AS ProductSerialNo,
                    DEREF(PB.BatchProduct).ProductCategory AS ProductCategory,
                    DEREF(PB.BatchProduct).ExpiryDate AS ProductExpiryDate
                FROM
                    ProductBatch PB
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

def departments():
    with st.expander("Departments", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    D.DepartmentID,
                    D.DeptContact.Email AS DepartmentEmail,
                    D.DeptContact.Fax AS DepartmentFax,
                    (SELECT LISTAGG(P.COLUMN_VALUE, ', ') WITHIN GROUP (ORDER BY ROWNUM)
                        FROM TABLE(D.DeptContact.PhoneNumbers) P) AS DepartmentPhoneNumbers,
                    (SELECT LISTAGG(DEREF(SP.COLUMN_VALUE).SerialNo, ', ')
                        FROM TABLE(D.SupplyPreferences) SP) AS SupplyPreferenceSerialNos
                FROM Department D
                '''
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from Department.")
            else:
                st.info("Department table is empty or no data accessible.")
        

def customers():
    with st.expander("Customers", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    C.CustomerCode,
                    DEREF(DeptRef.COLUMN_VALUE).DepartmentID AS DepartmentID,
                    DEREF(DeptRef.COLUMN_VALUE).DeptContact.Email AS DepartmentEmail,
                    DEREF(DeptRef.COLUMN_VALUE).DeptContact.Fax AS DepartmentFax,
                    (SELECT LISTAGG(Phone.COLUMN_VALUE, ', ') WITHIN GROUP (ORDER BY ROWNUM)
                    FROM TABLE(DEREF(DeptRef.COLUMN_VALUE).DeptContact.PhoneNumbers) Phone
                    ) AS DepartmentPhoneNumbers
                FROM
                    Customer C,
                    TABLE(C.BelongsToDepts) DeptRef
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

def team_members():
    with st.expander("Team Members", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                'SELECT * FROM TeamMember'
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from TeamMember.")
            else:
                st.info("TeamMember table is empty or no data accessible.")
                
def chief_officiers():
    with st.expander("Chief Officiers", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                'SELECT tm.TaxCode, tm.MemberName, tm.MemberSurname, tm.BirthDate, tm.EmploymentDate, co.StartDate FROM ChiefOfficier co, TeamMember tm WHERE co.TaxCode = tm.TaxCode'
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from ChiefOfficier.")
            else:
                st.info("ChiefOfficier table is empty or no data accessible.")

def logistic_teams():
    with st.expander("Logistic Teams", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    LT.TeamCode,
                    LT.TeamName,
                    DEREF(LT.TeamChief).TaxCode AS ChiefTaxCode,
                    DEREF(LT.TeamChief).MemberName AS ChiefName,
                    DEREF(LT.TeamChief).MemberSurname AS ChiefSurname,
                    LT.CompletedDeliveries,
                    DEREF(TM.COLUMN_VALUE).TaxCode AS MemberTaxCode,
                    DEREF(TM.COLUMN_VALUE).MemberName AS MemberName,
                    DEREF(TM.COLUMN_VALUE).MemberSurname AS MemberSurname,
                    DEREF(TM.COLUMN_VALUE).BirthDate AS MemberBirthDate,
                    DEREF(TM.COLUMN_VALUE).EmploymentDate AS MemberEmploymentDate
                FROM
                    LogisticTeam LT,
                    TABLE(LT.TeamMembers) TM
                '''
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from LogisticTeam.")
            else:
                st.info("LogisticTeam table is empty or no data accessible.")

def distribution_centers():
    with st.expander("Distribution Centers", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    DC.CenterName,                    
                    DEREF(P.COLUMN_VALUE).SerialNo AS ProductSerialNo,
                    DEREF(P.COLUMN_VALUE).ProductCategory AS ProductCategory,
                    DEREF(P.COLUMN_VALUE).ExpiryDate AS ProductExpiryDate
                FROM
                    DistributionCenter DC,
                    TABLE(DC.ListOfProducts) P
                '''
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from ViewDistCenterProducts.")
            else:
                st.info("ViewDistCenterProducts view is empty or no data accessible.")

def batch_orders():
    with st.expander("Batch Orders", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    BO.OrderID,
                    BO.OrderDate,
                    BO.ExpectedDeliveryDate,
                    BO.DeliveryStatus,
                    DEREF(BO.ByCustomer).CustomerCode AS CustomerCode,
                    DEREF(BO.ByCustomer).CustomerLocation.City AS CustomerCity,
                    DEREF(BO.ByCustomer).CustomerLocation.Street AS CustomerStreet,
                    DEREF(BO.ByCustomer).CustomerLocation.ZipCode AS CustomerZipCode,
                    DEREF(BO.ByLogisticTeam).TeamCode AS LogisticTeamCode,
                    DEREF(BO.ByLogisticTeam).TeamName AS LogisticTeamName
                FROM
                    BatchOrder BO
                '''
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from ViewBatchOrderDetails.")
            else:
                st.info("ViewBatchOrderDetails view is empty or no data accessible.")

def complaints():
    with st.expander("Complaints", expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT
                    C.TicketID,
                    C.ComplaintType,
                    C.StartDate AS ComplaintStartDate,
                    C.EndDate AS ComplaintEndDate,
                    DEREF(C.ByCustomer).CustomerCode AS CustomerCode,
                    DEREF(C.ByCustomer).CustomerLocation.City AS CustomerCity,
                    DEREF(C.ByCustomer).CustomerLocation.Street AS CustomerStreet,
                    DEREF(C.OnBatchOrder).OrderID AS BatchOrderID,
                    DEREF(C.OnBatchOrder).DeliveryStatus AS BatchOrderDeliveryStatus,
                    DEREF(C.OnBatchOrder).OrderDate AS BatchOrderDate
                FROM
                    Complaint C
                '''
            )
            rows = cursor.fetchall()
            if rows:
                columns = [desc[0] for desc in cursor.description]
                df = pd.DataFrame(rows, columns=columns)
                st.dataframe(df, use_container_width=True)
                st.info(f"Showing {len(df)} rows from Complaint.")
            else:
                st.info("Complaint table is empty or no data accessible.")

# --- Check if connected ---
if not db_utils.st.session_state.db_connected or not db_utils.st.session_state.logged_in_user:
    st.warning("You must be logged in to view this page. Please go to the **'Login'** page.")
else:
    st.write(f"Viewing data as: **`{db_utils.st.session_state.logged_in_user}`**")

    try:
        with db_utils.st.session_state.db_pool.acquire() as connection:
            products()
            product_batches()
            departments()
            customers()
            team_members()
            chief_officiers()
            logistic_teams()
            distribution_centers()
            batch_orders()
            complaints()

    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Database Error: {error_obj.message}")
        st.warning(f"Ensure `{db_utils.st.session_state.logged_in_user}` has SELECT privileges on ALL_TABLES.")
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
