CREATE TABLE Product OF Product_t
(
    SerialNo PRIMARY KEY,
    ProductCategory NOT NULL,
    CHECK (ProductCategory IN ('Medical Equipment', 'Supplies', 'Consumables'))
);
/

CREATE TABLE ProductBatch OF ProdBatch_t
(
    BatchID PRIMARY KEY,
    BatchProduct NOT NULL SCOPE IS Product,
    Quantity NOT NULL,
    ArrivalDate NOT NULL
);
/

CREATE TABLE Department OF Department_t
(
    DepartmentID PRIMARY KEY,
    DeptContact NOT NULL
)
NESTED TABLE SupplyPreferences STORE AS SupplyPreferencesNT;
/

CREATE TABLE Customer OF Customer_t
(
    CustomerCode PRIMARY KEY,
    CustomerLocation NOT NULL
)
NESTED TABLE BelongsToDepts STORE AS BelongsToDeptsNT;
/

CREATE TABLE TeamMember OF TeamMember_t
(
    TaxCode PRIMARY KEY,
    MemberName NOT NULL,
    MemberSurname NOT NULL,
    BirthDate NOT NULL,
    EmploymentDate NOT NULL
);
/

CREATE TABLE ChiefOfficier OF ChiefOfficier_t
(
    TaxCode PRIMARY KEY,
    StartDate NOT NULL
);
/

CREATE TABLE LogisticTeam OF LogisticTeam_t
(
    TeamCode PRIMARY KEY,
    TeamName NOT NULL,
    TeamChief NOT NULL SCOPE IS ChiefOfficier,
    CompletedDeliveries DEFAULT 0 NOT NULL
)
NESTED TABLE TeamMembers STORE AS TeamMembersNT;
/

CREATE TABLE DistributionCenter OF DistCenter_t
(
    CenterName PRIMARY KEY,
    ByTeam NOT NULL SCOPE IS LogisticTeam,
    CenterLocation NOT NULL
)
NESTED TABLE ListOfProducts STORE AS ListOfProductsNT;
/

CREATE TABLE BatchOrder OF BatchOrder_t
(
    OrderID PRIMARY KEY,
    OrderDate NOT NULL,
    ExpectedDeliveryDate NOT NULL,
    DeliveryStatus NOT NULL,
    ByCustomer NOT NULL SCOPE IS Customer,
    ByLogisticTeam NOT NULL SCOPE IS LogisticTeam,
    CHECK (DeliveryStatus IN (
        'Pending', 'In Transit', 'Delivered', 'Cancelled', 'Problem'
    ))
)
NESTED TABLE OrderBatches STORE AS OrderBatchesNT;
/

CREATE TABLE Complaint OF Complaint_t
(
    TicketID PRIMARY KEY,
    ByCustomer NOT NULL SCOPE IS Customer,
    OnBatchOrder NOT NULL SCOPE IS BatchOrder,
    ComplaintType NOT NULL,
    StartDate NOT NULL,
    CHECK (ComplaintType IN (
        'Delivery Delay', 'Missing Items', 'Damaged Goods', 'Other'
    ))
);
/