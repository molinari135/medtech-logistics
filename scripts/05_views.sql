CREATE OR REPLACE VIEW ViewDeptSupplyPreferences AS
SELECT
    d.DepartmentID,
    DEREF(pref.COLUMN_VALUE).SerialNo AS PreferredProductSerialNo,
    DEREF(pref.COLUMN_VALUE).ProductCategory AS PreferredProductCategory
FROM
    Department d,
    TABLE(d.SupplyPreferences) pref;
/

CREATE OR REPLACE VIEW ViewCustomerDeptAffiliation AS
SELECT
    c.CustomerCode,
    c.CustomerLocation.City AS CustomerCity,
    c.CustomerLocation.Street AS CustomerStreet,
    c.CustomerLocation.StreetNo AS CustomerStreetNo,
    c.CustomerLocation.ZipCode AS CustomerZipCode,
    DEREF(btd.COLUMN_VALUE).DepartmentID AS DepartmentID,
    DEREF(btd.COLUMN_VALUE).DeptContact.Email AS DepartmentEmail,
    DEREF(btd.COLUMN_VALUE).DeptContact.Fax AS DepartmentFax
FROM
    Customer c,
    TABLE(c.BelongsToDepts) btd;
/

CREATE OR REPLACE VIEW ViewLogisticTeamMembers AS
SELECT
    lt.TeamCode,
    lt.TeamName,
    DEREF(member.COLUMN_VALUE).TaxCode AS MemberTaxCode,
    DEREF(member.COLUMN_VALUE).MemberName AS MemberName,
    DEREF(member.COLUMN_VALUE).MemberSurname AS MemberSurname,
    DEREF(member.COLUMN_VALUE).EmploymentDate AS MemberEmploymentDate
FROM
    LogisticTeam lt,
    TABLE(lt.TeamMembers) member;
/

CREATE OR REPLACE VIEW ViewDistCenterProducts AS
SELECT
    dc.CenterName,
    dc.CenterLocation.City AS CenterCity,
    dc.CenterLocation.Street AS CenterStreet,
    DEREF(prod_list.COLUMN_VALUE).SerialNo AS StockedProductSerialNo,
    DEREF(prod_list.COLUMN_VALUE).ProductCategory AS StockedProductCategory,
    DEREF(prod_list.COLUMN_VALUE).ExpiryDate AS StockedProductExpiryDate
FROM
    DistributionCenter dc,
    TABLE(dc.ListOfProducts) prod_list;
/

CREATE OR REPLACE VIEW ViewBatchOrderDetails AS
SELECT
    bo.OrderID,
    bo.OrderDate,
    bo.ExpectedDeliveryDate,
    bo.DeliveryStatus,
    DEREF(batch_list.COLUMN_VALUE).BatchID AS IncludedBatchID,
    DEREF(batch_list.COLUMN_VALUE).Quantity AS IncludedBatchQuantity,
    DEREF(batch_list.COLUMN_VALUE).ArrivalDate AS IncludedBatchArrivalDate,
    DEREF(DEREF(batch_list.COLUMN_VALUE).BatchProduct).SerialNo AS ProductSerialNoInBatch,
    DEREF(DEREF(batch_list.COLUMN_VALUE).BatchProduct).ProductCategory AS ProductCategoryInBatch
FROM
    BatchOrder bo,
    TABLE(bo.OrderBatches) batch_list;
/

CREATE OR REPLACE VIEW ViewComplaintDetails AS
SELECT
    c.TicketID,
    c.ComplaintType,
    c.StartDate,
    c.EndDate,
    c.ByCustomer.CustomerCode AS CustomerCode,
    c.OnBatchOrder.OrderID AS OrderID
FROM
    Complaint c;
/