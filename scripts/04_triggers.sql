-- Data validation triggers for dates
CREATE OR REPLACE TRIGGER TrgTeamMemberDates
BEFORE INSERT OR UPDATE OF BirthDate, EmploymentDate ON TeamMember
FOR EACH ROW
BEGIN
    IF :NEW.EmploymentDate < :NEW.BirthDate THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employment date cannot be before birth date.');
    END IF;
    
    IF :NEW.EmploymentDate > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employment date cannot be in the future.');
    END IF;
END;
/

-- Ensure ArrivedDate of the batch is not in the future
CREATE OR REPLACE TRIGGER TrgProductBatchArrivalDate
BEFORE INSERT OR UPDATE OF ArrivalDate ON ProductBatch
FOR EACH ROW
BEGIN
    IF :NEW.ArrivalDate > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20009, 'Arrived date of the batch cannot be in the future.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TrgChiefOfficierStartDate
BEFORE INSERT OR UPDATE OF StartDate ON ChiefOfficier
FOR EACH ROW
DECLARE
    v_employment_date DATE;
BEGIN
    SELECT t.EmploymentDate INTO v_employment_date
    FROM TeamMember t
    WHERE t.TaxCode = :NEW.TaxCode;
    
    IF :NEW.StartDate < v_employment_date THEN
        RAISE_APPLICATION_ERROR(-20003, 'Chief officier start date cannot be before the employment date.');
    END IF;
    
    IF :NEW.StartDate > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Chief officer start date cannot be in the future.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TrgBatchOrderDates
BEFORE INSERT OR UPDATE OF OrderDate, ExpectedDeliveryDate ON BatchOrder
FOR EACH ROW
BEGIN
    IF :NEW.ExpectedDeliveryDate < :NEW.OrderDate THEN
        RAISE_APPLICATION_ERROR(-20005, 'Expected delivery date cannot be before order date.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TrgComplaintDates
BEFORE INSERT OR UPDATE OF StartDate, EndDate ON Complaint
FOR EACH ROW
BEGIN
    IF :NEW.EndDate IS NOT NULL AND :NEW.EndDate < :NEW.StartDate THEN
        RAISE_APPLICATION_ERROR(-20006, 'Complaint end date cannot be before start date.');
    END IF;
END;
/

-- Data consistencing triggers for deliveries
CREATE OR REPLACE TRIGGER TrgUpdateTeamDeliveries
AFTER UPDATE OF DeliveryStatus ON BatchOrder
FOR EACH ROW
BEGIN
    IF :OLD.DeliveryStatus <> 'Delivered' AND :NEW.DeliveryStatus = 'Delivered' THEN
        -- DEREF the ByLogisticTeam REF to get the actual LogisticTeam_t object
        -- Then access its TeamCode attribute (which is the PK of LogisticTeam table)
        UPDATE LogisticTeam
        SET CompletedDeliveries = CompletedDeliveries + 1
        WHERE TeamCode = DEREF(:NEW.ByLogisticTeam).TeamCode;
        -- The WHERE clause now compares the TeamCode attribute from the DEREFenced object
        -- with the TeamCode (PK) of the LogisticTeam table.
    END IF;
END;
/

-- Reassign a chief to a team if deleted
CREATE OR REPLACE TRIGGER TrgReassignTeamChief
BEFORE DELETE ON ChiefOfficier
FOR EACH ROW
DECLARE
    v_new_chief_tax_code TeamMember.TaxCode%TYPE;
BEGIN
    SELECT TaxCode
    INTO v_new_chief_tax_code
    FROM (
        SELECT TaxCode
        FROM TeamMember
        WHERE
            NOT EXISTS (SELECT 1 FROM ChiefOfficier WHERE ChiefOfficier.TaxCode = TeamMember.TaxCode)
        ORDER BY
            EmploymentDate ASC
        FETCH FIRST 1 ROW ONLY
    );
    
    UPDATE LogisticTeam
    SET TeamChief =
        (SELECT REF(c) FROM ChiefOfficier c WHERE c.TaxCode = v_new_chief_tax_code)
    WHERE TeamChief = (SELECT REF(co) FROM ChiefOfficier co WHERE co.TaxCode = :OLD.TaxCode);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'No suitable replacement chief officer found.');
END;
/

-- -- Ensure ProductBatch's product is in the available products list of the assigned distribution center
-- CREATE OR REPLACE TRIGGER TrgProductBatchProductInCenter
-- BEFORE INSERT OR UPDATE OF BatchProduct, ByDistCenter ON ProductBatch
-- FOR EACH ROW
-- DECLARE
--     v_count INTEGER;
-- BEGIN
--     SELECT COUNT(*) INTO v_count
--     FROM TABLE(DEREF(:NEW.ByDistCenter).AvailableProducts) p
--     WHERE p.SerialNo = DEREF(:NEW.BatchProduct).SerialNo;

--     IF v_count = 0 THEN
--         RAISE_APPLICATION_ERROR(
--             -20008,
--             'The selected product is not available at the assigned distribution center.'
--         );
--     END IF;
-- END;
-- /

-- Prevent inserting an expired product into a batch
CREATE OR REPLACE TRIGGER TrgNoExpiredProductInBatch
BEFORE INSERT OR UPDATE OF BatchProduct ON ProductBatch
FOR EACH ROW
DECLARE
    v_expiry_date DATE;
BEGIN
    SELECT p.ExpiryDate INTO v_expiry_date
    FROM Product p
    WHERE p.SerialNo = DEREF(:NEW.BatchProduct).SerialNo;

    IF v_expiry_date < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20010, 'Cannot insert an expired product into a batch.');
    END IF;
END;
/