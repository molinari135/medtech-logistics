DECLARE
    v_tax_code NUMBER;
BEGIN
    SELECT person_tax_code_seq.NEXTVAL INTO v_tax_code FROM DUAL;
    DBMS_OUTPUT.PUT_LINE('--- Testing TrgTeamMemberDates (Successful Insert) ---');
    INSERT INTO TeamMember (TaxCode, MemberName, MemberSurname, BirthDate, EmploymentDate)
    VALUES (v_tax_code, 'TestMember', 'Success', DATE '1990-01-15', DATE '2015-06-01');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully inserted TestMember. TaxCode: ' || v_tax_code);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error on successful insert test: ' || SQLERRM);
END;
/

DECLARE
    v_tax_code NUMBER;
BEGIN
    SELECT person_tax_code_seq.NEXTVAL INTO v_tax_code FROM DUAL;
    DBMS_OUTPUT.PUT_LINE('--- Testing TrgTeamMemberDates (Failing Insert - Employment before Birth) ---');
    INSERT INTO TeamMember (TaxCode, MemberName, MemberSurname, BirthDate, EmploymentDate)
    VALUES (v_tax_code, 'TestMember', 'Fail1', DATE '2000-01-01', DATE '1999-12-31');
    COMMIT; -- This will not be reached if trigger fires
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Expected Error (Employment before Birth): ' || SQLERRM);
END;
/

DECLARE
    v_tax_code NUMBER;
BEGIN
    -- Insert a valid record first to update
    SELECT person_tax_code_seq.NEXTVAL INTO v_tax_code FROM DUAL;
    INSERT INTO TeamMember (TaxCode, MemberName, MemberSurname, BirthDate, EmploymentDate)
    VALUES (v_tax_code, 'TestMember', 'ForUpdate', DATE '1985-05-10', DATE '2010-03-01');
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('--- Testing TrgTeamMemberDates (Failing Update - Employment in Future) ---');
    UPDATE TeamMember
    SET EmploymentDate = TRUNC(SYSDATE) + 10 -- 10 days in the future
    WHERE TaxCode = v_tax_code;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Expected Error (Employment in Future): ' || SQLERRM);
END;
/

DECLARE
    v_tax_code NUMBER;
    v_employment_date DATE;
BEGIN
    -- Find an existing TeamMember who is NOT yet a ChiefOfficier
    SELECT TaxCode, EmploymentDate
    INTO v_tax_code, v_employment_date
    FROM TeamMember tm
    WHERE NOT EXISTS (SELECT 1 FROM ChiefOfficier co WHERE co.TaxCode = tm.TaxCode)
    ORDER BY DBMS_RANDOM.VALUE
    FETCH FIRST 1 ROW ONLY;

    DBMS_OUTPUT.PUT_LINE('--- Testing TrgChiefOfficierStartDate (Successful Insert) ---');
    INSERT INTO ChiefOfficier (TaxCode, StartDate)
    VALUES (v_tax_code, v_employment_date + 365); -- StartDate 1 year after EmploymentDate
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully inserted ChiefOfficier. TaxCode: ' || v_tax_code);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Prerequisite Error: No eligible TeamMember found to promote to ChiefOfficier.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error on successful ChiefOfficier insert test: ' || SQLERRM);
END;
/

DECLARE
    v_tax_code NUMBER;
    v_employment_date DATE;
BEGIN
    -- Find an existing TeamMember who is NOT yet a ChiefOfficier
    SELECT TaxCode, EmploymentDate
    INTO v_tax_code, v_employment_date
    FROM TeamMember tm
    WHERE NOT EXISTS (SELECT 1 FROM ChiefOfficier co WHERE co.TaxCode = tm.TaxCode)
    ORDER BY DBMS_RANDOM.VALUE
    FETCH FIRST 1 ROW ONLY;

    DBMS_OUTPUT.PUT_LINE('--- Testing TrgChiefOfficierStartDate (Failing Insert - StartDate before EmploymentDate) ---');
    INSERT INTO ChiefOfficier (TaxCode, StartDate)
    VALUES (v_tax_code, v_employment_date - 10); -- StartDate 10 days before EmploymentDate
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Prerequisite Error: No eligible TeamMember found to promote to ChiefOfficier.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Expected Error (ChiefOfficier StartDate before EmploymentDate): ' || SQLERRM);
END;
/

DECLARE
    v_order_id             NUMBER;
    v_customer_ref         REF Customer_t;
    v_logistic_team_ref    REF LogisticTeam_t;
    v_product_batch_ref    REF ProdBatch_t;
    v_order_batches        BatchList := BatchList();
BEGIN
    SELECT batch_order_id_seq.NEXTVAL INTO v_order_id FROM DUAL;

    -- Get a random Customer REF
    SELECT REF(c) INTO v_customer_ref
    FROM Customer c ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    -- Get a random Logistic Team REF
    SELECT REF(lt) INTO v_logistic_team_ref
    FROM LogisticTeam lt ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    -- Get a random ProductBatch REF
    SELECT REF(pb) INTO v_product_batch_ref
    FROM ProductBatch pb ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    v_order_batches.EXTEND; v_order_batches(1) := v_product_batch_ref;

    DBMS_OUTPUT.PUT_LINE('--- Testing TrgBatchOrderDates (Successful Insert) ---');
    INSERT INTO BatchOrder (OrderID, OrderBatches, OrderDate, ExpectedDeliveryDate, DeliveryStatus, ByCustomer, ByLogisticTeam)
    VALUES (v_order_id, v_order_batches, DATE '2024-01-01', DATE '2024-01-10', 'Pending', v_customer_ref, v_logistic_team_ref);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully inserted BatchOrder. OrderID: ' || v_order_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Prerequisite Error: Ensure Customer, LogisticTeam, ProductBatch tables are populated.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error on successful BatchOrder insert test: ' || SQLERRM);
END;
/

DECLARE
    v_ticket_id       NUMBER;
    v_customer_ref    REF Customer_t;
    v_batch_order_ref REF BatchOrder_t;
BEGIN
    SELECT complaint_ticket_id_seq.NEXTVAL INTO v_ticket_id FROM DUAL;

    -- Get a random Customer REF
    SELECT REF(c) INTO v_customer_ref
    FROM Customer c ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    -- Get a random BatchOrder REF
    SELECT REF(bo) INTO v_batch_order_ref
    FROM BatchOrder bo ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    DBMS_OUTPUT.PUT_LINE('--- Testing TrgComplaintDates (Failing Insert - EndDate before StartDate) ---');
    INSERT INTO Complaint (TicketID, ByCustomer, OnBatchOrder, ComplaintType, StartDate, EndDate)
    VALUES (v_ticket_id, v_customer_ref, v_batch_order_ref, 'Other', DATE '2024-03-15', DATE '2024-03-01');
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Prerequisite Error: Ensure Customer, BatchOrder tables are populated.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Expected Error (Complaint EndDate before StartDate): ' || SQLERRM);
END;
/
