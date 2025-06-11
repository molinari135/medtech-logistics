-- DROP SEQUENCE person_tax_code_seq;
-- DROP SEQUENCE customer_id_seq;
-- DROP SEQUENCE department_id_seq;
-- DROP SEQUENCE product_serial_seq;
-- DROP SEQUENCE product_batch_id_seq;
-- DROP SEQUENCE logistic_team_id_seq;
-- DROP SEQUENCE batch_order_id_seq;
-- DROP SEQUENCE complaint_ticket_id_seq;
-- DROP SEQUENCE distribution_center_id_seq;

CREATE SEQUENCE person_tax_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE customer_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE department_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE product_serial_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE product_batch_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE logistic_team_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE batch_order_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE complaint_ticket_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE distribution_center_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

DECLARE
    -- No variables are strictly needed for this simple insert,
    -- but we'll use one to demonstrate how you might assign product serials.
    v_product_serial VARCHAR2(10);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Product Table ---');

    FOR i IN 1..50 LOOP -- Insert 50 sample products
        v_product_serial := LPAD(i, 3, '0'); -- Generates PROD-001, PROD-002, etc.

        INSERT INTO Product (SerialNo, ProductCategory, ExpiryDate)
        VALUES (
            v_product_serial,
            CASE
                WHEN MOD(i, 3) = 0 THEN 'Medical Equipment'
                WHEN MOD(i, 3) = 1 THEN 'Supplies'
                ELSE 'Consumables'
            END,
            SYSDATE + (DBMS_RANDOM.VALUE(1, 365) * 5) -- Expires randomly within the next 5 years
        );
    END LOOP;

    COMMIT; -- Save the changes to the database
    DBMS_OUTPUT.PUT_LINE('Successfully populated 50 products into the Product table.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Rollback if any error occurs
        DBMS_OUTPUT.PUT_LINE('Error populating Product table: ' || SQLERRM);
END;
/

DECLARE
    v_batch_id      NUMBER;
    v_product_ref   REF Product_t; -- Using Product_t, assuming your type is named this way
    v_product_serial VARCHAR2(10);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating ProductBatch Table ---');

    FOR i IN 1..200 LOOP -- Insert 200 sample product batches
        v_batch_id := product_batch_id_seq.NEXTVAL; -- Get the next ID from the sequence

        -- Randomly select an existing product's SerialNo
        SELECT SerialNo INTO v_product_serial
        FROM Product
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        -- Get the REF to that product
        SELECT REF(p) INTO v_product_ref
        FROM Product p
        WHERE p.SerialNo = v_product_serial;

        INSERT INTO ProductBatch (BatchID, BatchProduct, Quantity, ArrivalDate)
        VALUES (
            v_batch_id,
            v_product_ref,
            DBMS_RANDOM.VALUE(10, 500), -- Random quantity between 10 and 500 units
            SYSDATE - DBMS_RANDOM.VALUE(1, 365) -- Arrival date within the last year
        );
    END LOOP;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated 200 product batches into the ProductBatch table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No products found in the Product table. Please ensure the Product table is populated before running this script.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating ProductBatch table: ' || SQLERRM);
END;
/

DECLARE
    v_department_id NUMBER;
    v_contact_info  ContactInfo;
    v_phone_list    PhoneList;
    v_product_ref   REF Product_t; -- Correct type name for Product REF
    v_preferences_list PreferencesList;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Department Table ---');

    -- Ensure the sequence exists
    -- CREATE SEQUENCE department_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

    FOR i IN 1..10 LOOP -- Insert 10 sample departments
        v_department_id := department_id_seq.NEXTVAL;

        -- Create PhoneList
        v_phone_list := PhoneList(
            TO_NUMBER('111222' || LPAD(i, 3, '0')), -- Mobile number
            TO_NUMBER('333444' || LPAD(i, 3, '0'))  -- Office number
        );

        -- Create ContactInfo
        v_contact_info := ContactInfo(
            v_phone_list,
            'dept' || i || '@medtech.com',
            'fax' || LPAD(i, 2, '0') || '00'
        );

        -- Populate SupplyPreferences (NESTED TABLE)
        v_preferences_list := PreferencesList(); -- Initialize the nested table

        FOR j IN 1..DBMS_RANDOM.VALUE(5, 15) LOOP -- Each department has 5-15 preferred products
            SELECT REF(p) INTO v_product_ref
            FROM Product p
            ORDER BY DBMS_RANDOM.VALUE
            FETCH FIRST 1 ROW ONLY;

            v_preferences_list.EXTEND;
            v_preferences_list(v_preferences_list.LAST) := v_product_ref;
        END LOOP;

        INSERT INTO Department (DepartmentID, DeptContact, SupplyPreferences)
        VALUES (
            v_department_id,
            v_contact_info,
            v_preferences_list
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 10 departments into the Department table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No products found to add to SupplyPreferences. Ensure Product table is populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Department table: ' || SQLERRM);
END;
/

DECLARE
    v_customer_code    VARCHAR2(10);
    v_location         Location;
    v_department_ref   REF Department_t; -- Assuming Department_t for REF
    v_department_list  DepartmentList;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Customer Table ---');

    -- Ensure the sequence exists for CustomerCode (if you're using a sequence for it)
    -- CREATE SEQUENCE customer_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

    FOR i IN 1..50 LOOP -- Populating 50 sample customers
        v_customer_code := 'CUST' || LPAD(customer_id_seq.NEXTVAL, 3, '0');

        -- Create a sample Location object
        v_location := Location(
            'City ' || MOD(i, 10),
            'Street ' || i,
            TO_CHAR(MOD(i, 100) + 1), -- Street number
            MOD(i * 100 + 10000, 99999) + 1 -- 5-digit zip code
        );

        -- Populate BelongsToDepts (NESTED TABLE)
        v_department_list := DepartmentList(); -- Initialize the nested table

        FOR j IN 1..DBMS_RANDOM.VALUE(1, 3) LOOP -- Each customer belongs to 1-3 departments
            -- Get a random department REF
            SELECT REF(d) INTO v_department_ref
            FROM Department d
            ORDER BY DBMS_RANDOM.VALUE
            FETCH FIRST 1 ROW ONLY;

            -- Add to the nested table
            v_department_list.EXTEND;
            v_department_list(v_department_list.LAST) := v_department_ref;
        END LOOP;

        INSERT INTO Customer (CustomerCode, CustomerLocation, BelongsToDepts)
        VALUES (
            v_customer_code,
            v_location,
            v_department_list
        );
    END LOOP;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated 50 customers into the Customer table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Not enough departments found to link customers to. Please ensure the Department table is populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Customer table: ' || SQLERRM);
END;
/

DECLARE
    v_tax_code       NUMBER;
    v_birth_date     DATE;
    v_employment_date DATE;
    v_age_years      NUMBER;
    v_years_employed NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating TeamMember Table ---');

    -- Ensure the sequence exists for TaxCode
    -- CREATE SEQUENCE person_tax_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;

    FOR i IN 1..100 LOOP -- Populating 100 sample team members
        v_tax_code := person_tax_code_seq.NEXTVAL;

        -- Generate realistic birth and employment dates:
        -- Member is between 25 and 60 years old
        v_age_years := ROUND(DBMS_RANDOM.VALUE(25, 60));
        v_birth_date := ADD_MONTHS(TRUNC(SYSDATE), -(v_age_years * 12 + ROUND(DBMS_RANDOM.VALUE(0, 11))));

        -- Employment date is after birth date, and not in the future.
        -- Employed for 1 to (v_age_years - 20) years (to ensure they are at least 20 when employed)
        v_years_employed := ROUND(DBMS_RANDOM.VALUE(1, LEAST(v_age_years - 20, 30))); -- Max 30 years employed
        v_employment_date := ADD_MONTHS(TRUNC(SYSDATE), -(v_years_employed * 12 + ROUND(DBMS_RANDOM.VALUE(0, 11))));

        -- Ensure employment date is not in the future (due to TRUNC(SYSDATE), it won't be, but good to be explicit)
        IF v_employment_date > TRUNC(SYSDATE) THEN
            v_employment_date := TRUNC(SYSDATE) - DBMS_RANDOM.VALUE(0, 30); -- If somehow future, adjust to recent past
        END IF;

        -- Ensure employment date is after birth date
        IF v_employment_date < v_birth_date THEN
            v_employment_date := v_birth_date + ROUND(DBMS_RANDOM.VALUE(18 * 365, 25 * 365)); -- At least 18-25 years after birth
            IF v_employment_date > TRUNC(SYSDATE) THEN
                v_employment_date := TRUNC(SYSDATE) - DBMS_RANDOM.VALUE(0, 30); -- Still not in future
            END IF;
        END IF;

        INSERT INTO TeamMember (TaxCode, MemberName, MemberSurname, BirthDate, EmploymentDate)
        VALUES (
            v_tax_code,
            'MemberName' || LPAD(i, 3, '0'),
            'Surname' || LPAD(i, 3, '0'),
            v_birth_date,
            v_employment_date
        );
    END LOOP;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated 100 team members into the TeamMember table.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating TeamMember table: ' || SQLERRM);
END;
/

DECLARE
    v_chief_tax_code     NUMBER;
    v_employment_date    DATE;
    v_start_date         DATE;
    v_rows_processed     NUMBER := 0;

    -- Cursor to select existing TeamMembers who are NOT yet ChiefOfficers
    CURSOR c_eligible_members IS
        SELECT tm.TaxCode, tm.EmploymentDate
        FROM TeamMember tm
        WHERE NOT EXISTS (SELECT 1 FROM ChiefOfficier co WHERE co.TaxCode = tm.TaxCode)
        ORDER BY DBMS_RANDOM.VALUE; -- Pick random members
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating ChiefOfficier Table ---');

    OPEN c_eligible_members;
    LOOP
        FETCH c_eligible_members INTO v_chief_tax_code, v_employment_date;
        EXIT WHEN c_eligible_members%NOTFOUND OR v_rows_processed >= 25; -- Stop after 25 chiefs

        -- Generate StartDate for ChiefOfficier:
        -- Must be after EmploymentDate and not in the future.
        -- Let's say, 1 to 10 years after employment date, but not after today.
        v_start_date := v_employment_date + (DBMS_RANDOM.VALUE(1, 10) * 365); -- Add 1-10 years

        -- Ensure StartDate is not in the future
        IF v_start_date > TRUNC(SYSDATE) THEN
            v_start_date := TRUNC(SYSDATE) - DBMS_RANDOM.VALUE(0, 365); -- If future, set to recent past
            -- Make sure it's still after employment_date in case of very new employees
            IF v_start_date < v_employment_date THEN
                v_start_date := v_employment_date + DBMS_RANDOM.VALUE(1, 30); -- At least a few days after employment
            END IF;
        END IF;

        INSERT INTO ChiefOfficier (TaxCode, StartDate)
        VALUES (v_chief_tax_code, v_start_date);

        v_rows_processed := v_rows_processed + 1;
    END LOOP;
    CLOSE c_eligible_members;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated ' || v_rows_processed || ' chief officers into the ChiefOfficier table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No eligible team members found to promote to Chief Officer. Ensure TeamMember table is populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating ChiefOfficier table: ' || SQLERRM);
END;
/

DECLARE
    v_team_code         NUMBER;
    v_chief_ref         REF ChiefOfficier_t;
    v_team_member_ref   REF TeamMember_t;
    v_team_members_list MemberList; -- Type name as per your DDL
    v_chief_tax_code    ChiefOfficier.TaxCode%TYPE;
    v_member_tax_code   TeamMember.TaxCode%TYPE;
    v_rows_processed    NUMBER := 0;

    -- Cursor to select available chief officers (not already assigned as chief to a team)
    -- This is a simplification; in a real system, you might manage chief availability more complexly.
    CURSOR c_available_chiefs IS
        SELECT co.TaxCode
        FROM ChiefOfficier co
        WHERE NOT EXISTS (
            SELECT 1 FROM LogisticTeam lt
            WHERE lt.TeamChief = REF(co)
        )
        ORDER BY DBMS_RANDOM.VALUE;

    -- Cursor to select available team members (not chief officers, not already in this team)
    -- This picks general members, we'll try to ensure they are not chiefs.
    CURSOR c_available_members IS
        SELECT tm.TaxCode
        FROM TeamMember tm
        WHERE NOT EXISTS (SELECT 1 FROM ChiefOfficier co WHERE co.TaxCode = tm.TaxCode) -- Ensure not a chief
        ORDER BY DBMS_RANDOM.VALUE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating LogisticTeam Table ---');

    -- Ensure the sequence exists
    -- CREATE SEQUENCE logistic_team_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

    OPEN c_available_chiefs;
    FOR i IN 1..15 LOOP -- Attempt to create up to 15 teams
        FETCH c_available_chiefs INTO v_chief_tax_code;
        EXIT WHEN c_available_chiefs%NOTFOUND; -- Stop if no more chiefs available

        v_team_code := logistic_team_id_seq.NEXTVAL;

        -- Get the REF for the chosen chief
        SELECT REF(co) INTO v_chief_ref FROM ChiefOfficier co WHERE co.TaxCode = v_chief_tax_code;

        -- Populate TeamMembers (NESTED TABLE)
        v_team_members_list := MemberList(); -- Initialize the nested table

        OPEN c_available_members;
        FOR j IN 1..DBMS_RANDOM.VALUE(3, 7) LOOP -- Each team has 3-7 members
            FETCH c_available_members INTO v_member_tax_code;
            EXIT WHEN c_available_members%NOTFOUND;

            -- Get the REF for the chosen team member
            SELECT REF(tm) INTO v_team_member_ref FROM TeamMember tm WHERE tm.TaxCode = v_member_tax_code;

            -- Add to the nested table
            v_team_members_list.EXTEND;
            v_team_members_list(v_team_members_list.LAST) := v_team_member_ref;
        END LOOP;
        CLOSE c_available_members;

        -- If a team has no members (highly unlikely with this logic, but good to check)
        IF v_team_members_list IS NULL OR v_team_members_list.COUNT = 0 THEN
            -- Skip this team or handle as an error
            DBMS_OUTPUT.PUT_LINE('Warning: Skipping Team ' || v_team_code || ' as no members could be assigned.');
            CONTINUE;
        END IF;

        INSERT INTO LogisticTeam (TeamCode, TeamName, TeamChief, TeamMembers, CompletedDeliveries)
        VALUES (
            v_team_code,
            'LogTeam ' || LPAD(v_team_code, 2, '0'),
            v_chief_ref,
            v_team_members_list,
            DBMS_RANDOM.VALUE(0, 50) -- Random number of completed deliveries
        );
        v_rows_processed := v_rows_processed + 1;
    END LOOP;
    CLOSE c_available_chiefs;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated ' || v_rows_processed || ' logistic teams into the LogisticTeam table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Not enough chief officers or team members found. Ensure ChiefOfficier and TeamMember tables are populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating LogisticTeam table: ' || SQLERRM);
END;
/

DECLARE
    v_center_name       VARCHAR2(30);
    v_location          Location; -- Type name as per your DDL
    v_logistic_team_ref REF LogisticTeam_t;
    v_product_ref       REF Product_t; -- Type name as per your DDL
    v_product_list      ProductList; -- Type name as per your DDL
    v_team_code         LogisticTeam.TeamCode%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating DistributionCenter Table ---');

    -- Note: Your DDL uses CenterName as PRIMARY KEY, not a sequence-generated ID.
    -- So we'll construct CenterName directly.

    FOR i IN 1..15 LOOP -- Populating 15 sample distribution centers
        v_center_name := 'DC_' || LPAD(i, 2, '0') || '_HQ';

        -- Create a sample Location object
        v_location := Location(
            'City_DC_' || MOD(i, 5),
            'Street_DC_' || i,
            TO_CHAR(MOD(i, 20) + 1),
            MOD(i * 200 + 50000, 99999) + 1
        );

        -- Get a random Logistic Team REF
        -- Ensure there's at least one team in the LogisticTeam table
        SELECT TeamCode INTO v_team_code
        FROM LogisticTeam
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        SELECT REF(lt) INTO v_logistic_team_ref
        FROM LogisticTeam lt
        WHERE lt.TeamCode = v_team_code;


        -- Populate ListOfProducts (NESTED TABLE)
        v_product_list := ProductList(); -- Initialize the nested table

        FOR j IN 1..DBMS_RANDOM.VALUE(10, 30) LOOP -- Each center stocks 10-30 products
            -- Get a random Product REF
            SELECT REF(p) INTO v_product_ref
            FROM Product p
            ORDER BY DBMS_RANDOM.VALUE
            FETCH FIRST 1 ROW ONLY;

            -- Add to the nested table
            v_product_list.EXTEND;
            v_product_list(v_product_list.LAST) := v_product_ref;
        END LOOP;

        INSERT INTO DistributionCenter (CenterName, CenterLocation, ByTeam, ListOfProducts)
        VALUES (
            v_center_name,
            v_location,
            v_logistic_team_ref,
            v_product_list
        );
    END LOOP;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated 15 distribution centers into the DistributionCenter table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Not enough Logistic Teams or Products found. Ensure LogisticTeam and Product tables are populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating DistributionCenter table: ' || SQLERRM);
END;
/

DECLARE
    v_order_id             NUMBER;
    v_customer_ref         REF Customer_t;     -- Type name as per your DDL
    v_logistic_team_ref    REF LogisticTeam_t; -- Type name as per your DDL
    v_product_batch_ref    REF ProdBatch_t;    -- Type name as per your DDL
    v_order_batches        BatchList;          -- Type name as per your DDL
    v_customer_code        Customer.CustomerCode%TYPE;
    v_team_code            LogisticTeam.TeamCode%TYPE;
    v_batch_id             ProductBatch.BatchID%TYPE;
    v_order_date           DATE;
    v_expected_delivery_date DATE;
    v_delivery_status      VARCHAR2(15);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating BatchOrder Table ---');

    -- Ensure the sequence exists
    -- CREATE SEQUENCE batch_order_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

    FOR i IN 1..1000 LOOP -- Populating 1000 sample batch orders
        v_order_id := batch_order_id_seq.NEXTVAL;

        -- Get a random Customer REF
        SELECT CustomerCode INTO v_customer_code
        FROM Customer
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        SELECT REF(c) INTO v_customer_ref
        FROM Customer c
        WHERE c.CustomerCode = v_customer_code;

        -- Get a random Logistic Team REF
        SELECT TeamCode INTO v_team_code
        FROM LogisticTeam
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        SELECT REF(lt) INTO v_logistic_team_ref
        FROM LogisticTeam lt
        WHERE lt.TeamCode = v_team_code;

        -- Generate Order and Expected Delivery Dates
        v_order_date := TRUNC(SYSDATE) - DBMS_RANDOM.VALUE(0, 365); -- Order placed within the last year
        v_expected_delivery_date := v_order_date + DBMS_RANDOM.VALUE(1, 30); -- Expected delivery 1-30 days after order

        -- Ensure expected delivery date is not before order date (trigger validation)
        IF v_expected_delivery_date < v_order_date THEN
            v_expected_delivery_date := v_order_date + 1; -- At least 1 day after
        END IF;

        -- Choose a random DeliveryStatus
        v_delivery_status := CASE MOD(i, 5)
                                WHEN 0 THEN 'Pending'
                                WHEN 1 THEN 'In Transit'
                                WHEN 2 THEN 'Delivered'
                                WHEN 3 THEN 'Cancelled'
                                WHEN 4 THEN 'Problem'
                             END;

        -- Populate OrderBatches (NESTED TABLE)
        v_order_batches := BatchList(); -- Initialize the nested table

        -- Each order has 1 to 5 product batches
        FOR j IN 1..DBMS_RANDOM.VALUE(1, 5) LOOP
            -- Get a random ProductBatch REF
            SELECT BatchID INTO v_batch_id
            FROM ProductBatch
            ORDER BY DBMS_RANDOM.VALUE
            FETCH FIRST 1 ROW ONLY;

            SELECT REF(pb) INTO v_product_batch_ref
            FROM ProductBatch pb
            WHERE pb.BatchID = v_batch_id;

            -- Add to the nested table
            v_order_batches.EXTEND;
            v_order_batches(v_order_batches.LAST) := v_product_batch_ref;
        END LOOP;

        INSERT INTO BatchOrder (OrderID, OrderBatches, OrderDate, ExpectedDeliveryDate, DeliveryStatus, ByCustomer, ByLogisticTeam)
        VALUES (
            v_order_id,
            v_order_batches,
            v_order_date,
            v_expected_delivery_date,
            v_delivery_status,
            v_customer_ref,
            v_logistic_team_ref
        );
    END LOOP;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated 1000 batch orders into the BatchOrder table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Not enough Customers, Logistic Teams, or Product Batches found. Ensure these tables are populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating BatchOrder table: ' || SQLERRM);
END;
/

DECLARE
    v_ticket_id        NUMBER;
    v_customer_ref     REF Customer_t;   -- Type name as per your DDL
    v_batch_order_ref  REF BatchOrder_t; -- Type name as per your DDL
    v_customer_code    Customer.CustomerCode%TYPE;
    v_order_id         BatchOrder.OrderID%TYPE;
    v_complaint_type   VARCHAR2(20);
    v_start_date       DATE;
    v_end_date         DATE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Complaint Table ---');

    -- Ensure the sequence exists
    -- CREATE SEQUENCE complaint_ticket_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

    FOR i IN 1..200 LOOP -- Populating 200 sample complaints
        v_ticket_id := complaint_ticket_id_seq.NEXTVAL;

        -- Get a random Customer REF
        SELECT CustomerCode INTO v_customer_code
        FROM Customer
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        SELECT REF(c) INTO v_customer_ref
        FROM Customer c
        WHERE c.CustomerCode = v_customer_code;

        -- Get a random BatchOrder REF. Prioritize an order by this customer if available,
        -- otherwise pick any random order (since OnBatchOrder is NOT NULL).
        BEGIN
            SELECT OrderID INTO v_order_id
            FROM BatchOrder bo
            WHERE bo.ByCustomer = v_customer_ref -- Try to find an order by this customer
            ORDER BY DBMS_RANDOM.VALUE
            FETCH FIRST 1 ROW ONLY;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- If the chosen customer has no orders, pick any random order
                SELECT OrderID INTO v_order_id
                FROM BatchOrder
                ORDER BY DBMS_RANDOM.VALUE
                FETCH FIRST 1 ROW ONLY;
        END;

        SELECT REF(bo) INTO v_batch_order_ref
        FROM BatchOrder bo
        WHERE bo.OrderID = v_order_id;

        -- Choose a random ComplaintType
        v_complaint_type := CASE MOD(i, 4)
                                WHEN 0 THEN 'Delivery Delay'
                                WHEN 1 THEN 'Missing Items'
                                WHEN 2 THEN 'Damaged Goods'
                                WHEN 3 THEN 'Other'
                            END;

        -- Generate StartDate and optional EndDate
        v_start_date := TRUNC(SYSDATE) - DBMS_RANDOM.VALUE(0, 365); -- Complaint opened within the last year

        IF MOD(i, 2) = 0 THEN -- About 50% of complaints are resolved
            v_end_date := v_start_date + DBMS_RANDOM.VALUE(1, 60); -- Resolved within 1-60 days
            -- Ensure end date isn't in the future
            IF v_end_date > TRUNC(SYSDATE) THEN
                v_end_date := TRUNC(SYSDATE);
            END IF;
        ELSE
            v_end_date := NULL; -- Complaint is still open
        END IF;

        INSERT INTO Complaint (TicketID, ByCustomer, OnBatchOrder, ComplaintType, StartDate, EndDate)
        VALUES (
            v_ticket_id,
            v_customer_ref,
            v_batch_order_ref,
            v_complaint_type,
            v_start_date,
            v_end_date
        );
    END LOOP;

    COMMIT; -- Save all changes
    DBMS_OUTPUT.PUT_LINE('Successfully populated 200 complaints into the Complaint table.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Not enough Customers or Batch Orders found. Ensure these tables are populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Complaint table: ' || SQLERRM);
END;
/